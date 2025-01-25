import { db } from "./firebaseConfig";
import { doc, getDoc } from "firebase/firestore";

interface UserData {
  name: string;
  email: string;
  password: string;
}

// Fetch User Data
export const getUserData = async (uid: string): Promise<UserData | null> => {
  try {
    const userDoc = await getDoc(doc(db, "users", uid));
    if (userDoc.exists()) {
      return userDoc.data() as UserData;
    } else {
      return null;
    }
  } catch (error) {
    throw error;
  }
};
