// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'dart:ui';

import 'model/flight.dart';
import 'model/data.dart';
import 'app.dart';
import 'colors.dart';
//import 'menu_page.dart';

enum MenuStatus { showMenu, hideMenu, toggleForm }


double _kFlingVelocity = 2.0;
MenuStatus _menuStatus = MenuStatus.toggleForm;
bool _showForm = true;

class _FrontLayer extends StatelessWidget {
  const _FrontLayer({
    Key key,
    this.onTap,
    this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0)
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20.0),
        children: _buildFlightCards(context),
      )
    );
  }

  List<Card> _buildFlightCards(BuildContext context) {
    List<Flight> flights = getFlights(Category.findTrips);
    return flights.map((flight) {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: Text(flight.destination),
              subtitle: Text(flight.layover ? 'Layover' : 'Nonstop'),
            ),
          ],
        )
      );
    }).toList();
  }
}

// TODO(tianlun): Remove or repurpose
class _BackdropTitle extends AnimatedWidget {
  final Function onPress;
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle({
    Key key,
    Listenable listenable,
    this.onPress,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(frontTitle != null),
        assert(backTitle != null),
        super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    return new DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Row(children: <Widget>[
        // branded icon
        SizedBox(
          width: 72.0,
          child: IconButton(
            icon: Icon(
              Icons.menu,
              semanticLabel: 'menu',
            ),
            padding: EdgeInsets.only(right: 8.0),
            onPressed: this.onPress,
          ),
        ),
      ]),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two layers, front and back. The front layer is shown
/// by default, and slides down to show the back layer, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back layer is showing.
class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final List<Widget> backLayer;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    @required this.frontLayer,
    @required this.backLayer,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(frontLayer != null),
        assert(backLayer != null),
        assert(frontTitle != null),
        assert(backTitle != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with TickerProviderStateMixin {

  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;
  AnimationController _menuController;
  TabController _tabController;
  var _targetOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 0.0,
      vsync: this,
    );
    _menuController = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 0.0,
      vsync: this
    );
    _targetOpacity = 0.0;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _flingFrontLayer() {
    print('fling');
    _controller.fling(
        velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
    //_controller.fling(velocity: _kFlingVelocity);
  }

  Animation<RelativeRect> _buildLayerAnimation (BuildContext context, double layerTop) {
    Animation<RelativeRect> layerAnimation;

    if (_menuStatus == MenuStatus.toggleForm && _showForm) {
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, layerTop, 0.0, 0.0),
      ).animate(_controller.view);
    }
    else if (_menuStatus == MenuStatus.toggleForm && !_showForm) {
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, layerTop, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
      ).animate(_controller.view);
    }
    else if (_menuStatus == MenuStatus.hideMenu && _showForm) {
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, 550.0, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, layerTop, 0.0, 0.0),
      ).animate(_controller.view);
    }
    else if (_menuStatus == MenuStatus.hideMenu && !_showForm) {
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, 550.0, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
      ).animate(_controller.view);
    }
    else if (_menuStatus == MenuStatus.showMenu && _showForm) {
      // animate from open form height to menu open height
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, layerTop, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, 550.0, 0.0, 0.0),
      ).animate(_controller.view);
    }
    else { // _menuStatus == MenuStatus.showMenu && !_showForm
      // animate from closed form height to menu open height
      layerAnimation = RelativeRectTween(
        begin: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
        end: RelativeRect.fromLTRB(0.0, 550.0, 0.0, 0.0),
      ).animate(_controller.view);
    }
    return layerAnimation;
  }

  Widget _buildFlyStack(BuildContext context, BoxConstraints constraints) {
    final double flyLayerTop = 271+.0;

    Animation<RelativeRect> flyLayerAnimation =
        _buildLayerAnimation(context, flyLayerTop);

    return Stack(
//      key: _backdropKey,
      children: <Widget>[
        widget.backLayer[0],
        PositionedTransition(
          rect: flyLayerAnimation,
          child: _FrontLayer(
            onTap: _flingFrontLayer,
            child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepStack(BuildContext context, BoxConstraints constraints) {
    final double sleepLayerTop = 205+.0;

    Animation<RelativeRect> sleepLayerAnimation =
        _buildLayerAnimation(context, sleepLayerTop);

    return Stack(
//      key: _backdropKey,
      children: <Widget>[
        widget.backLayer[1],
        PositionedTransition(
          rect: sleepLayerAnimation,
          child: _FrontLayer(
            onTap: _flingFrontLayer,
            child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  Widget _buildEatStack(BuildContext context, BoxConstraints constraints) {
    final double eatLayerTop = 271+.0;

    Animation<RelativeRect> eatLayerAnimation =
    _buildLayerAnimation(context, eatLayerTop);

    return Stack(
//      key: _backdropKey,
      children: <Widget>[
        widget.backLayer[2],
        PositionedTransition(
          rect: eatLayerAnimation,
          child: _FrontLayer(
            onTap: _flingFrontLayer,
              child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  Widget _buildMainApp(BuildContext context) {
    void handleTabs (var tabIndex) {
      print('pressed');
      if (_tabController.index == tabIndex) {
        // if tapped on the tab that's already open
        setState(() {
          _flingFrontLayer();
          _menuStatus = MenuStatus.toggleForm;
        //  _showForm = !_showForm;
        });
      }
      else {
        // if tapped on a different tab
        _tabController.animateTo(tabIndex);
        if (!_showForm) {
          setState(() {
            //_menuStatus = MenuStatus.toggleForm;
            //_showForm = !_showForm;
            //_controller.reverse();
          });
        }
      }
    }

    var appBar = AppBar(
      brightness: Brightness.dark,
      elevation: 0.0,
      titleSpacing: 0.0,
      // TODO(tianlun): Replace IconButton icon with Crane logo.
      flexibleSpace: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(12.00, 24.0, 0.0, 0.0),
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                print(_showForm);
                setState(() {
                  _targetOpacity = 1.0;
                  _menuStatus = MenuStatus.showMenu;
                  _menuController.forward();
                  //_flingFrontLayer();
                });
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 24.0),
            height: 150.0,
            width: 300.0,
            child: Row(
              children: <Widget>[
                Container(
                  height: 64.0,
                  width: 96.0,
                  child: FlatButton(
                    child: Text('FLY'),
                    textColor: kCranePrimaryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    onPressed: () => handleTabs(0),
                  ),
                ),
                Container(
                  height: 64.0,
                  width: 96.0,
                  child: FlatButton(
                    child: Text('SLEEP'),
                    textColor: kCranePrimaryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    onPressed: () => handleTabs(1),
                  ),
                ),
                Container(
                  height: 64.0,
                  width: 96.0,
                  child: FlatButton(
                    child: Text('EAT'),
                    textColor: kCranePrimaryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    onPressed: () => handleTabs(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    print("controller: ${_controller.value}");
    print("menu: ${_menuController.value}");

    return Material(
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: appBar,
            body: TabBarView(
              controller: _tabController,
              children: <Widget>[
                LayoutBuilder(
                  builder: _buildFlyStack,
                ),
                LayoutBuilder(
                  builder: _buildSleepStack,
                ),
                LayoutBuilder(
                  builder: _buildEatStack,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _menuController,
            child: _buildMenu(context),
            builder: _buildMenuTransition,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTransition(BuildContext context, Widget child) {
    return _menuController.status != AnimationStatus.dismissed ?
        FadeTransition(
          opacity: _menuController,
          child: child,
        ) : Container();
  }

  Widget _buildMenu(BuildContext context) {
    return Material(
      child: Container(
        constraints: BoxConstraints(maxWidth: 375.0, maxHeight: 400.0),
        padding: EdgeInsets.only(top: 40.0),
        color: kCranePurple800,
        child: ListView(
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                semanticLabel: 'back',
              ),
              onPressed: (){
                setState(() {
                  _menuStatus = MenuStatus.hideMenu;
                  _menuController.reverse();
                  _targetOpacity = 0.0;

                  //_flingFrontLayer();
                });
              }
            ),
            Text('Find Trips'),
            Text('My Trips'),
            Text('Saved Trips'),
            Text('Price Alerts'),
            Text('My Account'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: _buildMainApp(context),
    );
  }
}
