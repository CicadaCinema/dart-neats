import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';

class LintAnalyzerPlugin extends ServerPlugin {
  LintAnalyzerPlugin({required super.resourceProvider});

  @override
  Future<void> analyzeFile(
      {required AnalysisContext analysisContext, required String path}) async {
    final parsedUnit = analysisContext.currentSession.getParsedUnit(path);
    if (parsedUnit is! ParsedUnitResult) {
      return;
    }

    final unit = parsedUnit.unit;
    final visitor = IdentifierVisitor(
      path: path,
      lineInfo: unit.lineInfo,
    );
    visitor.visitCompilationUnit(unit);

    channel.sendNotification(
      AnalysisErrorsParams(
        path,
        visitor.methodLocations
            .map((Location location) => AnalysisError(
                  AnalysisErrorSeverity.INFO,
                  AnalysisErrorType.LINT,
                  location,
                  'I\'m a method invocation',
                  'my_lint_code',
                  correction: 'A correction message',
                  hasFix: false,
                ))
            .toList(),
      ).toNotification(),
    );
  }

  @override
  List<String> get fileGlobsToAnalyze => ['*.dart'];

  @override
  String get name => 'Simple plugin';

  @override
  String get version => '1.0.0';
}

// For reference see https://github.com/CicadaCinema/pana/blob/70cd8006209d495d2aa9b42d42862dc179efee7f/lib/src/package_analysis/lower_bound_constraint_analysis.dart#L246 .
class IdentifierVisitor extends RecursiveAstVisitor {
  final methodLocations = <Location>[];

  final String path;
  final LineInfo lineInfo;

  IdentifierVisitor({
    required this.path,
    required this.lineInfo,
  });

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // An invocation of a top-level function or a class method.
    super.visitMethodInvocation(node);

    final nodeLocation = lineInfo.getLocation(node.offset);
    final nodeLocationEnd = lineInfo.getLocation(node.end);

    methodLocations.add(Location(
      path,
      node.offset,
      node.length,
      nodeLocation.lineNumber,
      nodeLocation.columnNumber,
      endLine: nodeLocationEnd.lineNumber,
      endColumn: nodeLocationEnd.columnNumber,
    ));
  }
}
