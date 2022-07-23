import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/route_argument.dart';
import '../models/statistic.dart';
import '../models/user.dart';
import '../repository/dashboard_repository.dart';
import '../repository/order_repository.dart';
import '../repository/user_repository.dart';

import '../helpers/helper.dart';
import '../repository/user_repository.dart' as userRepo;
import 'package:http/http.dart' as http;
import 'package:global_configuration/global_configuration.dart';
import 'package:just_audio/just_audio.dart';

class OrderController extends ControllerMVC {
  Order order;
  List<Order> orders = <Order>[];
  List<OrderStatus> orderStatuses = <OrderStatus>[];
  List<User> drivers = <User>[];
  List<String> selectedStatuses;
  List<Statistic> statistics = <Statistic>[];
  GlobalKey<ScaffoldState> scaffoldKey;
  bool isAberto = false;
  bool isDelivery = false;  


  bool possui_novo_pedido = false;
  final player = AudioPlayer();

  OrderController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    inicializaAudio();

  }

  void inicializaAudio() async{
    try {
      var duration = await player.setUrl(GlobalConfiguration().getValue('base_url')+'/notification.mp3');
      player.load();
    } catch (e) {
      print(e.toString());
    }
  }

  void alteraStatusFuncionamento(bool aberto,bool delivery) async{
    Uri uri = Helper.getUri('api/manager/users/altera_aberto_and_delivery');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;

    _queryParams['api_token'] = _user.apiToken;
    _queryParams['aberto'] = aberto==true?"1":"0";
    _queryParams['delivery'] = delivery==true?"1":"0";
    uri = uri.replace(queryParameters: _queryParams);

    try {
      print(uri);
      final client = new http.Client();
      await client.send(http.Request('get', uri));      
    } catch (e) {
      print(e.toString());
      //return new Stream.value(User.fromJSON({}));
      //return null;
    }
  }

  void listenForStatusFuncionamento() async{
    Uri uri = Helper.getUri('api/manager/users/aberto_and_delivery');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;

    _queryParams['api_token'] = _user.apiToken;
    uri = uri.replace(queryParameters: _queryParams);

    try {
      print(uri);
      final client = new http.Client();
      final response = await client.send(http.Request('get', uri));
      final string = await response.stream.bytesToString();     
      Map<String,dynamic> funcionamento = json.decode(string)['data'];
      setState(() {
        isAberto = funcionamento['aberto']; 
        isDelivery = funcionamento['delivery'];
      });
      //Aberprint(funcionamento['aberto']);
      //return string;
    } catch (e) {
      print(e.toString());
      //return new Stream.value(User.fromJSON({}));
      //return null;
    }
  }

  void checaNovoPedido() async{
    Uri uri = Helper.getUri('api/manager/users/checa_novo_pedido');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;
    if(!orders.isEmpty){
      _queryParams['api_token'] = _user.apiToken;
      String lastId = orders.firstWhere((element) => element.active).id.toString();
      _queryParams['last_pedido_id'] = lastId;    
      uri = uri.replace(queryParameters: _queryParams);    
      print(uri);
      try {          
        final client = new http.Client();
        await client.send(http.Request('get', uri));
        final response = await client.send(http.Request('get', uri));
        final string = await response.stream.bytesToString();     
        Map<String,dynamic> data = json.decode(string);
        print(data);
        possui_novo_pedido = data['possui_novo_pedido'];                           
        if(possui_novo_pedido){          
          player.load();
          player.play();
          refreshOrders();
          listenForStatusFuncionamento();          
        }
      } catch (e) {
        print(e.toString());
        //return new Stream.value(User.fromJSON({}));
        //return null;
      }
    }    
  }

  void listenForStatistics({String message}) async {
    final Stream<Statistic> stream = await getStatistics();
    stream.listen((Statistic _stat) {
      setState(() {
        statistics.add(_stat);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {});
  }

  void listenForOrderStatus({String message, bool insertAll}) async {
    final Stream<OrderStatus> stream = await getOrderStatuses();
    stream.listen((OrderStatus _orderStatus) {
      setState(() {
        orderStatuses.add(_orderStatus);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (insertAll != null && insertAll) {
        orderStatuses.insert(0, new OrderStatus.fromJSON({'id': '0', 'status': context != null ? S.of(context).all : ''}));
      }
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForDrivers({String message}) async {
    final Stream<User> stream = await getDriversOfMarket(this.order?.productOrders[0]?.product?.market?.id ?? '0');
    stream.listen((User _driver) {
      setState(() {
        drivers.add(_driver);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForOrders({statusesIds, String message}) async {
    final Stream<Order> stream = await getOrders(statusesIds: statusesIds);
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForOrder({String id, String message, bool withDrivers = false}) async {
    final Stream<Order> stream = await getOrder(id);
    stream.listen((Order _order) {
      setState(() => order = _order);
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      selectedStatuses = [order.orderStatus.id];
      if (withDrivers) {
        listenForDrivers();
      }
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> selectStatus(List<String> statusesIds) async {
    orders.clear();
    listenForOrders(statusesIds: statusesIds);
  }

  Future<void> refreshOrder() async {
    listenForOrder(id: order.id, message: S.of(context).order_refreshed_successfuly);
  }

  Future<void> refreshOrders() async {
    
    orders.clear();
    statistics.clear();
    listenForStatistics();
    listenForOrders(statusesIds: selectedStatuses, message: S.of(context).order_refreshed_successfuly);
  }

  void doUpdateOrder(Order _order) async {
    updateOrder(_order).then((value) {
      Navigator.of(context).pushNamed('/OrderDetails', arguments: RouteArgument(id: order.id));
//      FocusScope.of(context).unfocus();
//      setState(() {
//        this.order.orderStatus.id = '5';
//      });
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).thisOrderUpdatedSuccessfully),
      ));
    });
  }

  void doCancelOrder(Order order) {
    cancelOrder(order).then((value) {
      setState(() {
        order.active = false;
      });
    }).catchError((e) {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(e),
      ));
    }).whenComplete(() {
      //refreshOrders();
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).orderIdHasBeenCanceled(order.id)),
      ));
    });
  }
}
