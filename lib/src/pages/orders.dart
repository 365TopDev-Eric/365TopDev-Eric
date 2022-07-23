import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:markets_owner/src/elements/menu_icon.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:wakelock/wakelock.dart';

import '../controllers/order_controller.dart';
import '../elements/EmptyOrdersWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import '../repository/settings_repository.dart' as settingsRepo;

class OrdersWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  OrdersWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends StateMVC<OrdersWidget> {
  OrderController _con;

  _OrdersWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  void initState() {
    _con.listenForStatusFuncionamento();
    _con.listenForOrders();
    _con.listenForStatistics();
    _con.listenForOrderStatus(insertAll: true);
    _con.selectedStatuses = ['0'];
    Wakelock.enable();
    executaChecagemNovoPedido();

    super.initState();
  }

  void executaChecagemNovoPedido() {
    Timer.periodic(new Duration(seconds: 10), (timer) {
      _con.checaNovoPedido();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.scaffoldKey,
      appBar: AppBar(
        leading: new IconButton(
          icon: MenuIcon(),
          onPressed: () => widget.parentScaffoldKey.currentState.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ValueListenableBuilder(
          valueListenable: settingsRepo.setting,
          builder: (context, value, child) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.asset(
                'assets/img/logo2.png',
                height: 160,
                width: 160,
              ),
            );
          },
        ),
        actions: <Widget>[
          new ShoppingCartButtonWidget(
              iconColor: Theme.of(context).hintColor, labelColor: Theme.of(context).accentColor),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          _con.refreshOrders;
          _con.listenForStatusFuncionamento();
        },
        child: ListView(
          children: [
            //StatisticsCarouselWidget(statisticsList: _con.statistics),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                            child: Transform.scale(
                          scale: 1.5,
                          child: Switch(
                            value: _con.isAberto,
                            onChanged: (value) {
                              setState(() {
                                _con.isAberto = value;
                                _con.alteraStatusFuncionamento(_con.isAberto, _con.isDelivery);
                              });
                            },
                            activeTrackColor: Colors.green,
                            activeColor: Colors.green,
                          ),
                        )),
                        Container(
                          padding: EdgeInsets.fromLTRB(50, 2, 50, 20),
                          child: Text(
                            "Aberto",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        )
                      ]),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                            child: Transform.scale(
                          scale: 1.5,
                          child: Switch(
                            value: _con.isDelivery,
                            onChanged: (value) {
                              setState(() {
                                _con.isDelivery = value;
                                _con.alteraStatusFuncionamento(_con.isAberto, _con.isDelivery);
                              });
                            },
                            activeTrackColor: Colors.green,
                            activeColor: Colors.green,
                          ),
                        )),
                        Container(
                          padding: EdgeInsets.fromLTRB(50, 2, 50, 20),
                          child: Text(
                            "Delivery Ativo",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        )
                      ])
                ],
              ),
            ),
            Stack(
              children: [
                if (_con.orders.isEmpty)
                  EmptyOrdersWidget()
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      primary: false,
                      itemCount: _con.orders.length,
                      itemBuilder: (context, index) {
                        var _order = _con.orders.elementAt(index);
                        return OrderItemWidget(
                          expanded: index == 0 ? true : false,
                          order: _order,
                          onCanceled: (e) {
                            _con.doCancelOrder(_order);
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return SizedBox(height: 20);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
