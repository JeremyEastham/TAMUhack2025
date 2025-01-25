import React, { useState } from "react";
import { View, TextInput, Button, Text } from "react-native";
import { logIn } from "../firebase/auth";
import Home from "../components/Home";

const HomeScreen: React.FC = () => {
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");

  const handleLogin = async () => {
    try {
      const user = await logIn(email, password);
      console.log("Logged in:", user);
    } catch (error: any) {
      console.error(error.message);
    }
  };

  return (
    <Home></Home>
  );
};

export default HomeScreen;
