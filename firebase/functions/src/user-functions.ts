import * as functions from "firebase-functions";
import * as Firestore from "@google-cloud/firestore";
import { User } from "./Models/User";

const firestore = new Firestore.Firestore();

export const userCreated = functions.auth.user().onCreate(async (data) => {
    const userId = data.uid;
    console.log("Display Name: " + data.displayName + ", Email: " + data.email);
    let displayName = "";
    let email = "";
    if (data.displayName) {
        displayName = data.displayName;
    }
    if (data.email) {
        email = data.email;
    }

    const user = new User();
    user.profile.displayName = displayName;
    user.profile.email = email;

    // Update user data
    const document = "users/" + userId;
    const documentRef = firestore.doc(document);
    await documentRef.set(user, { merge: true });
    console.log("User created: " + userId);
});
