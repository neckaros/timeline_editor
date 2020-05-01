import 'package:flutter/widgets.dart';

class CachedLayoutBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      builder;
  final List<dynamic> parentParameters;

  const CachedLayoutBuilder({Key key, this.builder, this.parentParameters})
      : super(key: key);
  @override
  _CachedLayoutBuilderState createState() => _CachedLayoutBuilderState();
}

class _CachedLayoutBuilderState extends State<CachedLayoutBuilder> {
  Widget previousBuild;
  BoxConstraints previousContraints;
  List<dynamic> previousParameters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      var parametersIdentical = true;
      if (previousParameters == null ||
          widget.parentParameters == null ||
          previousParameters.length != widget.parentParameters.length) {
        parametersIdentical = false;
      } else {
        for (var i = 0; i < previousParameters.length; i++) {
          if (previousParameters[i] != widget.parentParameters[i]) {
            parametersIdentical = false;
            break;
          }
        }
      }
      previousParameters = widget.parentParameters;
      if (!parametersIdentical || previousContraints != constraints) {
        previousBuild = widget.builder(ctx, constraints);
        previousContraints = constraints;
      }
      return previousBuild;
    });
  }
}
