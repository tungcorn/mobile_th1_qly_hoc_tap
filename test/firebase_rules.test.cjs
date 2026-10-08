const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, setDoc, updateDoc, getDoc, getDocs, deleteDoc, serverTimestamp } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject, listAll } = require('firebase/storage');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-studydoc',
    firestore: { host: '127.0.0.1', port: 8080,
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8') },
    storage: { host: '127.0.0.1', port: 9199,
      rules: readFileSync(resolve(__dirname, '../storage.rules'), 'utf8') },
  });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  // rules-unit-testing.clearStorage only removes objects at the bucket root.
  await env.withSecurityRulesDisabled(async (context) => {
    async function clearPrefix(prefix) {
      const listing = await listAll(prefix);
      await Promise.all(listing.items.map(deleteObject));
      await Promise.all(listing.prefixes.map(clearPrefix));
    }
    await clearPrefix(ref(context.storage('gs://demo-studydoc.appspot.com')));
  });
});

const bytes = new TextEncoder().encode('StudyDoc Firebase rules demo');
const path = 'users/alice/documents/doc1/file';
const metadata = (changes = {}) => ({
  ownerId: 'alice', title: 'Cloud lesson', subject: 'Cloud', note: '',
  fileName: 'demo.txt', contentType: 'text/plain', size: bytes.length,
  storagePath: path, createdAt: serverTimestamp(), ...changes,
});
const dbFor = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const storageFor = (uid) => uid ? env.authenticatedContext(uid).storage('gs://demo-studydoc.appspot.com')
  : env.unauthenticatedContext().storage('gs://demo-studydoc.appspot.com');
const document = (uid = 'alice') => doc(dbFor(uid), 'users/alice/documents/doc1');
const object = (uid = 'alice') => ref(storageFor(uid), path);
async function seed() {
  await setDoc(document(), metadata());
  await uploadBytes(object(), bytes, { contentType: 'text/plain' });
}

test('owner can create/read/list/update/delete their metadata', async () => {
  await assertSucceeds(setDoc(document(), metadata()));
  const snapshot = await assertSucceeds(getDoc(document()));
  assert.equal(snapshot.data().title, 'Cloud lesson');
  const list = await assertSucceeds(getDocs(collection(dbFor('alice'), 'users/alice/documents')));
  assert.equal(list.size, 1);
  await assertSucceeds(updateDoc(document(), { title: 'Updated', note: 'New note' }));
  await assertSucceeds(deleteDoc(document()));
});
test('owner can upload and download the exact file bytes', async () => {
  await assertSucceeds(uploadBytes(object(), bytes, { contentType: 'text/plain' }));
  const downloaded = await assertSucceeds(getBytes(object()));
  assert.deepEqual(new Uint8Array(downloaded), bytes);
  await assertSucceeds(deleteObject(object()));
});
test('another account cannot read or list owner metadata', async () => {
  await seed();
  await assertFails(getDoc(document('bob')));
  await assertFails(getDocs(collection(dbFor('bob'), 'users/alice/documents')));
});
test('another account cannot create/update/delete owner metadata', async () => {
  await assertFails(setDoc(document('bob'), metadata()));
  await seed();
  await assertFails(updateDoc(document('bob'), { title: 'Stolen' }));
  await assertFails(deleteDoc(document('bob')));
});
test('another account cannot read/overwrite/delete owner file', async () => {
  await seed();
  await assertFails(getBytes(object('bob')));
  await assertFails(uploadBytes(object('bob'), bytes, { contentType: 'text/plain' }));
  await assertFails(deleteObject(object('bob')));
});
test('anonymous requests cannot access metadata or files', async () => {
  await seed();
  await assertFails(getDoc(document(null)));
  await assertFails(setDoc(document(null), metadata()));
  await assertFails(getBytes(object(null)));
  await assertFails(deleteObject(object(null)));
});
test('forged owner identity is rejected', async () => {
  await assertFails(setDoc(document(), metadata({ ownerId: 'bob' })));
});
test('a metadata path pointing at another user is rejected', async () => {
  await assertFails(setDoc(document(), metadata({ storagePath: 'users/bob/documents/doc1/file' })));
});
test('oversized/empty/unknown metadata fields are rejected', async () => {
  await assertFails(setDoc(document(), metadata({ title: '' })));
  await assertFails(setDoc(document(), metadata({ title: 'a'.repeat(251) })));
  await assertFails(setDoc(document(), metadata({ size: 10 * 1024 * 1024 + 1 })));
  await assertFails(setDoc(document(), metadata({ publicUrl: 'https://example.test' })));
});
test('client-chosen timestamp is rejected in favor of serverTimestamp', async () => {
  await assertFails(setDoc(document(), metadata({ createdAt: new Date('2020-01-01') })));
});
test('owner cannot change immutable object identity', async () => {
  await seed();
  await assertFails(updateDoc(document(), { fileName: 'replaced.txt' }));
  await assertFails(updateDoc(document(), { ownerId: 'bob' }));
  await assertFails(updateDoc(document(), { size: 1 }));
});
test('invalid content types are rejected even if client bypasses UI', async () => {
  await assertFails(uploadBytes(object(), bytes, { contentType: 'application/x-msdownload' }));
});
test('empty file is rejected by Storage rules', async () => {
  await assertFails(uploadBytes(object(), new Uint8Array(), { contentType: 'text/plain' }));
});
test('file at the exact size limit is accepted', async () => {
  await assertSucceeds(uploadBytes(object(), new Uint8Array(10 * 1024 * 1024), { contentType: 'application/pdf' }));
});
test('file over the size limit is rejected', async () => {
  await assertFails(uploadBytes(object(), new Uint8Array(10 * 1024 * 1024 + 1), { contentType: 'application/pdf' }));
});
test('owner cannot overwrite an existing immutable file', async () => {
  await seed();
  await assertFails(uploadBytes(object(), bytes, { contentType: 'text/plain' }));
});
test('unknown paths and recursive bucket listing are denied', async () => {
  await assertFails(setDoc(doc(dbFor('alice'), 'public/doc1'), metadata()));
  await assertFails(uploadBytes(ref(storageFor('alice'), 'public/demo.txt'), bytes, { contentType: 'text/plain' }));
  await assertFails(listAll(ref(storageFor('bob'), 'users/alice/documents')));
});
