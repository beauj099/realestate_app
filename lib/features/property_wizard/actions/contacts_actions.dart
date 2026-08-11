import '../data/models/contact.dart';
import '../data/models/property_state.dart';

extension ContactsActions on PropertyState {
  PropertyState withPrimaryContact(Contact contact) =>
      copyWith(primaryContact: contact);

  PropertyState withAddedCoContact() {
    final newContact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return copyWith(coContacts: [...coContacts, newContact]);
  }

  PropertyState withUpdatedCoContact(int index, Contact contact) {
    final updated = List<Contact>.from(coContacts);
    if (index >= 0 && index < updated.length) {
      updated[index] = contact;
      return copyWith(coContacts: updated);
    }
    return this;
  }

  PropertyState withRemovedCoContact(String id) =>
      copyWith(coContacts: coContacts.where((c) => c.id != id).toList());
}
