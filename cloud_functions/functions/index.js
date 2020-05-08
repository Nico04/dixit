'use strict';

// ---- Inits ----
const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp();

// Since this code will be running in the Cloud Functions environment we call initialize Firestore without any arguments because it detects authentication from the environment.
const firestore = admin.firestore();

const httpsFunction = functions.region('europe-west1').https;

// ---- Functions ----
// Clean outdated Dixit rooms
exports.cleanRooms = httpsFunction.onRequest(async (request, response) => {
  // List all documents
  var rooms = await firestore.collection('rooms').listDocuments();
  console.log('rooms.length = ' + rooms.length);

  // Duration const, in milliseconds
  const day = 1000 * 3600 * 24;   

  // Delete old rooms
  for (const roomRef of rooms) {
    // get room data    
    var room = (await roomRef.get()).data();

    // Extract data
    const createDate = Date.parse(room.createDate);
    const createdSince = Date.now() - createDate;
    const endDate = Date.parse(room.endDate);

    // Delete if either :
    // - rooms > 1 month
    // - unstarted rooms > 1 day
    // - ended rooms > 1 day
    if (createdSince > day * 30
        || !room.startDate && createdSince > day 
        || Date.now() - endDate > day) {
      
      // Delete room
      await roomRef.delete();

      // Log
      console.log(`Room '${room.name}' deleted`);
    }
  }

  // End
  response.send('Travail terminé !');
});