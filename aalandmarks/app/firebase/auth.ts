import { auth, db } from "./firebaseConfig";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  UserCredential,
} from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";

// User data type
interface UserData {
  name: string;
  email: string;
}

// Sign Up Function
export const signUp = async (
  name: string,
  email: string,
  password: string
): Promise<UserCredential> => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Add user data to Firestore
    const userData: UserData = { name, email };
    await setDoc(doc(db, "users", user.uid), userData);

    return userCredential;
  } catch (error) {
    throw error;
  }
};

// Login Function
export const logIn = async (
  email: string,
  password: string
): Promise<UserCredential> => {
  try {
    return await signInWithEmailAndPassword(auth, email, password);
  } catch (error) {
    throw error;
  }
};
