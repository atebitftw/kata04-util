// Copyright (c) 2015, John Evans (prujohn@gmail.com). All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Common web utilities for the Kata project.
library kata.util.web;

import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';

part 'src/web.dart';

final Logger _l = new Logger("kata.util.web");