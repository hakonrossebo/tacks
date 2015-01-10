package models

import core.CourseGenerator
import play.api.libs.concurrent.Execution.Implicits._
import org.joda.time.{LocalDate, DateTime}
import reactivemongo.bson._
import reactivemongo.core.commands._
import tools.BSONHandlers.BSONDateTimeHandler

import scala.concurrent.Future
import scala.util.Try

case class TimeTrial(
  _id: BSONObjectID = BSONObjectID.generate,
  slug: String,
  period: String,
  course: Course,
  countdownSeconds: Int = 20,
  creationTime: DateTime = DateTime.now
) extends HasId

object TimeTrial extends MongoDAO[TimeTrial] {
  val collectionName = "time_trials"

  val periodFormat = "YYYY-MM"

  def currentPeriod = LocalDate.now.toString(periodFormat)
  def parsePeriod(p: String): LocalDate = Try(LocalDate.parse(p)).toOption.getOrElse(LocalDate.now)

  def isOpen(t: TimeTrial) = t.period == TimeTrial.currentPeriod

  def listCurrent: Future[Seq[TimeTrial]] = listForPeriod(currentPeriod)

  def listForPeriod(period: String): Future[Seq[TimeTrial]] = {
    val futures = CourseGenerator.all.map(gen => TimeTrial.findBySlugAndPeriod(gen.slug, period))
    Future.sequence(futures).map(_.flatten)
  }
  
  def listForSlug(slug: String): Future[Seq[TimeTrial]] = {
    list(BSONDocument("slug" -> slug), BSONDocument("period" -> -1))
  }

  def zipWithRankings(timeTrials: Seq[TimeTrial]): Future[Seq[(TimeTrial, Seq[RunRanking])]] =
    Future.sequence(timeTrials.map(t => TimeTrialRun.rankings(t.id).map(r => (t, r.sortBy(_.rank)))))

//  def topWithPlayer(playerId: BSONObjectID, rankings: Seq[RunRanking], rankingLength: Int): Seq[RunRanking] =
//    rankings.filter(r => r.rank <= rankingLength || r.playerId == playerId).sortBy(_.rank)

  def findCurrentBySlug(slug: String): Future[Option[TimeTrial]] = findBySlugAndPeriod(slug, currentPeriod)

  def findBySlugAndPeriod(slug: String, period: String): Future[Option[TimeTrial]] = {
    collection.find(BSONDocument("slug" -> slug, "period" -> period)).one[TimeTrial]
  }

  def ensureIndexes(): Unit = {
    import reactivemongo.api.indexes.Index
    import reactivemongo.api.indexes.IndexType._

    collection.indexesManager.ensure(Index(
      key = List("slug" -> Ascending, "period" -> Descending),
      unique = true))
  }

  implicit val bsonReader: BSONDocumentReader[TimeTrial] = Macros.reader[TimeTrial]
  implicit val bsonWriter: BSONDocumentWriter[TimeTrial] = Macros.writer[TimeTrial]
}


case class TimeTrialRun(
  _id: BSONObjectID = BSONObjectID.generate,
  timeTrialId: BSONObjectID,
  playerId: BSONObjectID,
  tally: Seq[Long] = Nil,
  finishTime: Option[Long] = None
) extends HasId {
  def creationTime = idTime
}

case class RunRanking(
  rank: Int,
  playerId: BSONObjectID,
  runId: BSONObjectID,
  finishTime: Long
) {
  def creationTime = new DateTime(runId.time)
  def isRecent = creationTime.plusDays(1).isAfterNow
}

object TimeTrialRun extends MongoDAO[TimeTrialRun] {
  val collectionName = "time_trial_runs"

  def updateTimes(id: BSONObjectID, tally: Seq[Long], finishTime: Option[Long]): Future[_] = {
    update(id, BSONDocument("tally" -> tally, "finishTime" -> finishTime))
  }

  def rankings(trialId: BSONObjectID): Future[Seq[RunRanking]] = {
    val cmd = Aggregate(collectionName, Seq(
      Match(BSONDocument("timeTrialId" -> trialId, "finishTime" -> BSONDocument("$exists" -> true))),
      Sort(Seq(Ascending("finishTime"))),
      GroupMulti("playerId" -> "playerId")("runId" -> First("_id"), "finishTime" -> First("finishTime")),
      Sort(Seq(Ascending("finishTime")))
    ))

    db.command(cmd).map { bsonStream =>
      for {
        (doc, i) <- bsonStream.toSeq.zipWithIndex
        id <- doc.getAs[BSONDocument]("_id")
        playerId <- id.getAs[BSONObjectID]("playerId")
        finishTime <- doc.getAs[Long]("finishTime")
        runId <- doc.getAs[BSONObjectID]("runId")
      }
      yield RunRanking(i + 1, playerId, runId, finishTime)
    }
  }

  def filterClose(playerRanking: RunRanking, allRankings: Seq[RunRanking], count: Int): Seq[RunRanking] = {
    val (fasters, lowers) = allRankings
      .filterNot(_.playerId == playerRanking.playerId)
      .sortBy(_.finishTime)
      .partition(_.finishTime < playerRanking.finishTime)

    fasters.takeRight(count - 1) ++ lowers.take(1)
  }

  def findGhosts(trial: TimeTrial, playerRun: TimeTrialRun, count: Int = 5): Future[Seq[GhostRun]] = {
    for {
      ranking <- rankings(trial.id)
      playerRankingOpt = ranking.find(_.playerId == playerRun.playerId)
      selectedRankings = playerRankingOpt match {
        case Some(r) => filterClose(r, ranking, count - 1) :+ r
        case None => scala.util.Random.shuffle(ranking).take(count)
      }
      runs <- listByIds(selectedRankings.map(_.runId))
      tracks <- Future.sequence(runs.map(r => RunTrack.listForRun(r.id)))
      players <- User.listByIds(runs.map(_.playerId))
    }
    yield runs.zip(tracks).map { case (run, track) =>
      GhostRun(run, track, run.playerId, players.find(_.id == run.playerId).map(_.handle))
    }
  }

  def clean(runId: BSONObjectID): Future[LastError] = {
    for {
      _ <- RunTrack.removeRun(runId)
      e <- remove(runId)
    }
    yield e
  }

  implicit val bsonReader: BSONDocumentReader[TimeTrialRun] = Macros.reader[TimeTrialRun]
  implicit val bsonWriter: BSONDocumentWriter[TimeTrialRun] = Macros.writer[TimeTrialRun]
}

