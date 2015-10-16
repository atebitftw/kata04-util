// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// This library exposes all other libraries in kata.util, or you can just
/// import each library individually.
library kata.util;
import 'package:logging/logging.dart';

export 'kata_util_web.dart';
export 'kata_util_data.dart';

final Logger _l = new Logger("kata.util");
