import 'package:flutter/material.dart';

import '../models/user.dart';

class DrawerHeaderApp extends StatefulWidget {
  final User user;

  const DrawerHeaderApp({
    Key key,
    @required this.user,
  }) : super(key: key);

  @override
  State<DrawerHeaderApp> createState() => _DrawerHeaderAppState();
}

class _DrawerHeaderAppState extends State<DrawerHeaderApp> {
  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withOpacity(0.1),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsetsDirectional.only(top: 16.0, start: 16.0),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              // radius: 30,
              minRadius: 30,
              maxRadius: 30,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/img/account_icon.png'),
            ),
            const SizedBox(height: 14),
            Text(
              widget.user.name ?? 'N/A',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email ?? 'N/A',
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
