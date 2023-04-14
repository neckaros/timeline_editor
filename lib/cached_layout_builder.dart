import 'package:flutter/widgets.dart';

class CachedLayoutBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      builder;
  final List<dynamic> parentParameters;

  const CachedLayoutBuilder({
    super.key,
    required this.builder,
    required this.parentParameters,
  });

  @override
  State<CachedLayoutBuilder> createState() => _CachedLayoutBuilderState();
}

class _CachedLayoutBuilderState extends State<CachedLayoutBuilder> {
  late Widget previousBuild;
  BoxConstraints? previousContraints;
  List<dynamic> previousParameters = [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      var parametersIdentical = true;
      if (previousParameters.length != widget.parentParameters.length) {
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
