/*
 * @flow
 * @format
 */

import type {SuiteType} from '../../Tester';
const {join} = require('path');
const {suite, test} = require('../../Tester');

module.exports = (suite(
  ({
    lspStartAndConnect,
    lspRequestAndWaitUntilResponse,
    lspNotification,
    addFile,
    addFiles,
    modifyFile,
    lspIgnoreStatusAndCancellation,
  }) => [
    test(
      'textDocument/publishDiagnostics flowconfig enabled, no client config',
      [
        lspStartAndConnect(),
        addFile('file_with_simple_error.js')
          .waitUntilLSPMessage(
            9000,
            'textDocument/publishDiagnostics',
            '{Cannot assign}',
          )
          .verifyLSPMessageSnapshot(
            join(__dirname, '__snapshots__', 'has-detailed-errors.json'),
            ['window/showStatus', '$/cancelRequest'],
          ),
      ],
    ).flowConfig('_flowconfig_enabled'),

    test('textDocument/publishDiagnostics flowconfig enabled, client enabled', [
      lspStartAndConnect(),
      lspNotification('workspace/didChangeConfiguration', {
        settings: {detailedErrorRendering: true},
      }).verifyAllLSPMessagesInStep(
        [],
        [
          'textDocument/publishDiagnostics',
          'window/showStatus',
          '$/cancelRequest',
        ],
      ),
      addFile('file_with_simple_error.js')
        .waitUntilLSPMessage(
          9000,
          'textDocument/publishDiagnostics',
          '{Cannot assign}',
        )
        .verifyLSPMessageSnapshot(
          join(__dirname, '__snapshots__', 'has-detailed-errors.json'),
          ['window/showStatus', '$/cancelRequest'],
        ),
    ]).flowConfig('_flowconfig_enabled'),

    test(
      'textDocument/publishDiagnostics flowconfig enabled, client disabled',
      [
        lspStartAndConnect(),
        lspNotification('workspace/didChangeConfiguration', {
          settings: {detailedErrorRendering: false},
        }).verifyAllLSPMessagesInStep(
          [],
          [
            'textDocument/publishDiagnostics',
            'window/showStatus',
            '$/cancelRequest',
          ],
        ),
        addFile('file_with_simple_error.js')
          .waitUntilLSPMessage(
            9000,
            'textDocument/publishDiagnostics',
            '{Cannot assign}',
          )
          .verifyLSPMessageSnapshot(
            join(__dirname, '__snapshots__', 'no-detailed-errors.json'),
            ['window/showStatus', '$/cancelRequest'],
          ),
      ],
    ).flowConfig('_flowconfig_enabled'),

    test(
      'textDocument/publishDiagnostics flowconfig disabled, no client config',
      [
        lspStartAndConnect(),
        addFile('file_with_simple_error.js')
          .waitUntilLSPMessage(
            9000,
            'textDocument/publishDiagnostics',
            '{Cannot assign}',
          )
          .verifyLSPMessageSnapshot(
            join(__dirname, '__snapshots__', 'no-detailed-errors.json'),
            ['window/showStatus', '$/cancelRequest'],
          ),
      ],
    ).flowConfig('_flowconfig_disabled'),

    test(
      'textDocument/publishDiagnostics flowconfig disabled, client enabled',
      [
        lspStartAndConnect(),
        lspNotification('workspace/didChangeConfiguration', {
          settings: {detailedErrorRendering: true},
        }).verifyAllLSPMessagesInStep(
          [],
          [
            'textDocument/publishDiagnostics',
            'window/showStatus',
            '$/cancelRequest',
          ],
        ),
        addFile('file_with_simple_error.js')
          .waitUntilLSPMessage(
            9000,
            'textDocument/publishDiagnostics',
            '{Cannot assign}',
          )
          .verifyLSPMessageSnapshot(
            join(__dirname, '__snapshots__', 'has-detailed-errors.json'),
            ['window/showStatus', '$/cancelRequest'],
          ),
      ],
    ).flowConfig('_flowconfig_disabled'),

    test(
      'textDocument/publishDiagnostics flowconfig disabled, client disabled',
      [
        lspStartAndConnect(),
        lspNotification('workspace/didChangeConfiguration', {
          settings: {detailedErrorRendering: false},
        }).verifyAllLSPMessagesInStep(
          [],
          [
            'textDocument/publishDiagnostics',
            'window/showStatus',
            '$/cancelRequest',
          ],
        ),
        addFile('file_with_simple_error.js')
          .waitUntilLSPMessage(
            9000,
            'textDocument/publishDiagnostics',
            '{Cannot assign}',
          )
          .verifyLSPMessageSnapshot(
            join(__dirname, '__snapshots__', 'no-detailed-errors.json'),
            ['window/showStatus', '$/cancelRequest'],
          ),
      ],
    ).flowConfig('_flowconfig_disabled'),
  ],
): SuiteType);
