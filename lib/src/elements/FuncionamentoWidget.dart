import 'package:flutter/material.dart';
import 'package:markets_owner/src/controllers/market_controller.dart';

import '../repository/user_repository.dart' as userRepo;
class FuncionamentoWidget extends StatefulWidget {

  

  @override
  _FuncionamentoWidgetState createState() => _FuncionamentoWidgetState();
}

class _FuncionamentoWidgetState extends State<FuncionamentoWidget> {
  
  
  _FuncionamentoWidgetState() : super(){        
    userRepo.getAbertoAndDelivery();    
  }

  @override
  void initState() {
    // TODO: implement initState
    userRepo.getAbertoAndDelivery();    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return null;
  }
}