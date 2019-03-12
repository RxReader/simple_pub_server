// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http/http.dart' as http;
import 'package:pub_server/shelf_pubserver.dart';
import 'package:simple_pub_server/cow_repository.dart';
import 'package:simple_pub_server/file_repository.dart';
import 'package:simple_pub_server/http_proxy_repository.dart';

final Uri pubDartLangOrg = Uri.parse('https://pub.dartlang.org');

void main(List<String> args) {
  ArgParser parser = argsParser();
  ArgResults results = parser.parse(args);

  String directory = results['directory'] as String;
  String host = '0.0.0.0'; // 不能用 localhost
  int port = 8080;
  bool standalone = results['standalone'] as bool;

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  setupLogger();
  runPubServer(directory, host, port, standalone);
}

Future<HttpServer> runPubServer(
    String baseDir, String host, int port, bool standalone) {
  http.Client client = new http.Client();

  FileRepository local = new FileRepository(baseDir);
  HttpProxyRepository remote = new HttpProxyRepository(client, pubDartLangOrg);
  CopyAndWriteRepository cow =
      new CopyAndWriteRepository(local, remote, standalone);

  ShelfPubServer pubServer = new ShelfPubServer(cow);

  return shelf_io.serve(
      const Pipeline()
          .addMiddleware(logRequests())
          .addHandler((Request request) async {
        if (request.method == 'GET') {
          if (request.requestedUri.path == '/') {
            String body = 'Dart version: ${Platform.version}\n' +
                'Dart executable: ${Platform.executable}\n' +
                'Dart executable arguments: ${Platform.executableArguments}\n';
            return Response.ok(body, headers: <String, String>{
              HttpHeaders.contentTypeHeader: ContentType.text.toString(),
            });
          }
        }
        return await pubServer.requestHandler(request);
      }),
      host,
      port);
}

ArgParser argsParser() {
  var parser = new ArgParser();

  parser.addOption('directory',
      abbr: 'd',
      defaultsTo: Platform.environment['PUB_SERVER_REPOSITORY_DATA'] ??
          '/tmp/package-db');

  parser.addFlag('standalone',
      abbr: 's',
      defaultsTo: Platform.environment['PUB_SERVER_STANDALONE'] == 'true');
  return parser;
}

void setupLogger() {
  Logger.root.onRecord.listen((LogRecord record) {
    var head = '${record.time} ${record.level} ${record.loggerName}';
    var tail = record.stackTrace != null ? '\n${record.stackTrace}' : '';
    print('$head ${record.message} $tail');
  });
}
