import React, { createContext, useState, useEffect, ReactNode, useContext } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "../firebase/firebaseConfig";

interface AuthContextType {
  user: User | null;
  token: string | null;
  saveUser: (user: User | null) => void;
  saveToken: (token: string | null) => void;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);

      if (currentUser) {
        // Fetch and save the token if the user is logged in
        const fetchedToken = await currentUser.getIdToken();
        setToken(fetchedToken);
      } else {
        setToken(null);
      }
    });

    return () => unsubscribe();
  }, []);

  const saveUser = (user: User | null) => setUser(user);
  const saveToken = (token: string | null) => setToken(token);

  return (
    <AuthContext.Provider value={{ user, token, saveUser, saveToken }}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook to use AuthContext
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
