import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moments_remembered/main.dart';

void main() {
  test('app root is a Material widget', () {
    expect(const MomentsRememberedApp(), isA<StatelessWidget>());
  });
}
