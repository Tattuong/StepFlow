import 'flow.dart';

FlowOption _go(String id, String label, String detail, String next) => FlowOption(id: id, label: label, detail: detail, nextStepId: next);

FlowOption _end(String id, String label, String detail, {bool issue = false, String issueText = ''}) =>
    FlowOption(id: id, label: label, detail: detail, recordsIssue: issue, issueText: issueText);

FlowOption _issue(String id, String label, String detail, String next, String issueText) =>
    FlowOption(id: id, label: label, detail: detail, nextStepId: next, recordsIssue: true, issueText: issueText);

class PlaybookCatalog {
  PlaybookCatalog._();

  static List<Playbook> builtIns() => [_pack(), _room(), _laptop()];

  static Playbook _pack() => Playbook(
        id: 'pack-order',
        title: 'Pack an order',
        subtitle: 'Prepare items for safe dispatch.',
        icon: 'box',
        builtIn: true,
        steps: [
          FlowStep(
            id: 'p1',
            title: 'Gather packing materials',
            body: 'Collect a box, tape, and filler.',
            requiresConfirm: true,
            options: [_go('p1c', 'Ready', 'Materials are on the table.', 'p2')],
          ),
          FlowStep(
            id: 'p2',
            title: 'Check item details',
            body: 'Match the name, quantity, and order note.',
            options: [_go('p2c', 'Matched', 'The item matches the order.', 'p3')],
          ),
          FlowStep(
            id: 'p3',
            title: 'Is the item intact?',
            body: 'Check for visible damage before packing.',
            options: [
              _go('p3y', 'Yes', 'Item is in good condition.', 'p4'),
              _issue('p3n', 'No', 'Item is damaged or not intact.', 'p4', 'Box replaced before dispatch'),
            ],
          ),
          FlowStep(
            id: 'p4',
            title: 'Pack the item securely',
            body: 'Cushion the item and seal the box.',
            options: [_go('p4c', 'Packed', 'The box is sealed.', 'p5')],
          ),
          FlowStep(
            id: 'p5',
            title: 'Add labels and documentation',
            body: 'Attach the address label and packing note.',
            options: [
              _go('p5y', 'Yes', 'Labels are on the box.', 'p6'),
              _issue('p5n', 'No', 'A label is missing.', 'p6', 'Label reprinted before dispatch'),
            ],
          ),
          FlowStep(
            id: 'p6',
            title: 'Confirm ready for dispatch',
            body: 'Check the seal, label, and weight.',
            requiresConfirm: true,
            options: [
              _end('p6y', 'Yes', 'Ready to send.'),
              _end('p6n', 'No', 'Hold the parcel.', issue: true, issueText: 'Dispatch held for a recheck'),
            ],
          ),
        ],
      );

  static Playbook _room() => Playbook(
        id: 'return-room',
        title: 'Return a room',
        subtitle: 'Reset a room after a guest stays.',
        icon: 'bed',
        builtIn: true,
        steps: [
          FlowStep(
            id: 'r1',
            title: 'Has the guest checked out?',
            body: 'Do not enter until checkout is confirmed.',
            options: [
              _go('r1y', 'Yes', 'The room is vacant.', 'r2'),
              _end('r1n', 'No', 'Wait for checkout.', issue: true, issueText: 'Room still occupied'),
            ],
          ),
          FlowStep(id: 'r2', title: 'Strip the bed', body: 'Remove used linen and remake the bed.', options: [_go('r2c', 'Done', 'Fresh linen is on.', 'r3')]),
          FlowStep(
            id: 'r3',
            title: 'Any damage in the room?',
            body: 'Look at furniture, walls, and the remote.',
            options: [
              _go('r3n', 'No', 'Nothing is damaged.', 'r4'),
              _issue('r3y', 'Yes', 'Something needs a repair note.', 'r4', 'Damage noted for maintenance'),
            ],
          ),
          FlowStep(id: 'r4', title: 'Restock supplies', body: 'Replace towels, water, and coffee.', options: [_go('r4c', 'Restocked', 'Supplies match the list.', 'r5')]),
          FlowStep(
            id: 'r5',
            title: 'Is the bathroom clean?',
            body: 'Check the sink, shower, and floor.',
            options: [
              _go('r5y', 'Yes', 'Bathroom is ready.', 'r6'),
              _issue('r5n', 'No', 'It needs another pass.', 'r6', 'Bathroom cleaned again'),
            ],
          ),
          FlowStep(id: 'r6', title: 'Set the temperature', body: 'Leave the room at the standard setting.', options: [_go('r6c', 'Set', 'Climate is set.', 'r7')]),
          FlowStep(
            id: 'r7',
            title: 'Photo taken?',
            body: 'A photo confirms the room is ready.',
            options: [
              _go('r7y', 'Yes', 'Photo is saved.', 'r8'),
              _go('r7n', 'Take it now', 'Pause and photograph the room.', 'r8'),
            ],
          ),
          FlowStep(
            id: 'r8',
            title: 'Mark the room ready',
            body: 'Confirm the room can be sold again.',
            requiresConfirm: true,
            options: [_end('r8y', 'Ready', 'The room is back in service.')],
          ),
        ],
      );

  static Playbook _laptop() => Playbook(
        id: 'hand-laptop',
        title: 'Hand over a laptop',
        subtitle: 'Prepare and check before handover.',
        icon: 'laptop',
        builtIn: true,
        steps: [
          FlowStep(
            id: 'l1',
            title: 'Does the asset tag match?',
            body: 'Compare the sticker with the handover note.',
            options: [
              _go('l1y', 'Yes', 'This is the right laptop.', 'l2'),
              _end('l1n', 'No', 'Stop and find the correct device.', issue: true, issueText: 'Wrong asset tag'),
            ],
          ),
          FlowStep(
            id: 'l2',
            title: 'Does it power on?',
            body: 'Start it and reach the login screen.',
            options: [
              _go('l2y', 'Yes', 'It reaches the login screen.', 'l3'),
              _issue('l2n', 'No', 'It does not start.', 'l3', 'Laptop did not power on'),
            ],
          ),
          FlowStep(
            id: 'l3',
            title: 'Is the charger in the bag?',
            body: 'Include the cable that belongs to this model.',
            options: [
              _go('l3y', 'Yes', 'Charger is packed.', 'l4'),
              _issue('l3n', 'No', 'The charger is missing.', 'l4', 'Charger missing at handover'),
            ],
          ),
          FlowStep(
            id: 'l4',
            title: 'Are work accounts signed out?',
            body: 'Sign out of mail, chat, and the browser.',
            requiresConfirm: true,
            options: [
              _go('l4y', 'Yes', 'Accounts are signed out.', 'l5'),
              _issue('l4n', 'Not yet', 'Sign out before continuing.', 'l5', 'Accounts still signed in'),
            ],
          ),
          FlowStep(
            id: 'l5',
            title: 'Any physical damage?',
            body: 'Check the screen, keyboard, and ports.',
            options: [
              _go('l5n', 'No', 'The case looks fine.', 'l6'),
              _issue('l5y', 'Yes', 'Note the mark or crack.', 'l6', 'Physical damage noted'),
            ],
          ),
          FlowStep(id: 'l6', title: 'Files copied for the recipient?', body: 'Only share what the note lists.', options: [_go('l6c', 'Copied', 'The agreed files are ready.', 'l7')]),
          FlowStep(
            id: 'l7',
            title: 'Recipient signed?',
            body: 'Get a name and time on the handover note.',
            requiresConfirm: true,
            options: [_end('l7y', 'Signed', 'Handover is complete.')],
          ),
        ],
      );
}
