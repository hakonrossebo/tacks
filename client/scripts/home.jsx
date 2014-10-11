/**
 * @jsx React.DOM
 */

var React         = require('react');
var BaconMixin    = require('react-bacon').BaconMixin;
var Router        = require('react-router');
var $             = require('jquery');
var _             = require('lodash');
var Board         = require('./board');
var FinishedRaces = require('./finishedRaces');
var Api           = require('./api');
var util          = require('./util');

var Home = React.createClass({
  mixins: [BaconMixin],

  getInitialState: function() {
    return {
      userName: null,
      racesStatus: [],
      loadingNewRace: false
    };
  },

  componentWillMount: function() {
    this.plug(this.props.userName.changes(), 'userName');
    this.setState({ userName: this.props.userName.get() });
  },

  componentDidMount: function() {
    this.loadStatus()
    var intervalId = setInterval(this.loadStatus, 1000);
    this.setState({ intervalId: intervalId });
  },

  componentWillUnmount: function() {
    clearInterval(this.state.intervalId);
  },

  loadStatus: function() {
    $.ajax(Api.racesStatus()).done(function(racesStatus) {
      var waiting = _.filter(racesStatus.openRaces, (rs) => !rs.race.startTime).length;
      if (waiting > 0) {
        document.title = "(" + waiting + ") Play Tacks";
      } else {
        document.title = "Play Tacks"
      }
      this.setState({ racesStatus: racesStatus, loadingNewRace: false });
    }.bind(this));
  },

  changeName: function(e) {
    e.preventDefault();
    var newName = window.prompt("New name?", this.state.userName);

    util.post(Api.setName(), { name: newName }).done(function(res) {
      this.props.userName.set(newName);
    }.bind(this));
  },

  createRace: function(e) {
    e.preventDefault();
    if (this.state.loadingNewRace) return;

    this.setState({ loadingNewRace: true}, function() {
      util.post(Api.createRace()).done(function(race) {
        setTimeout(function() {
          this.setState({ loadingNewRace: false});
          // Router.transitionTo("playRace", { id: race._id});
        }.bind(this), 1000);
      }.bind(this));
    }.bind(this));
  },

  formatOnlinePlayers: function(status) {
    return (_.map(_.sortBy(status.onlinePlayers, 'name'), 'name')).join(", ");
  },

  render: function() {
    return (
      <div className="home">
        <Board status={this.state.racesStatus} />

        <a href="" onClick={this.createRace} className={util.cx({"btn-new-race": true, "loading": this.state.loadingNewRace })}>New race</a>

        <p>Online players: {this.formatOnlinePlayers(this.state.racesStatus)}</p>
      </div>
    );
  }

});

module.exports = Home;
