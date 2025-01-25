import React, { useState } from "react";
import { View, TextInput, Button } from "react-native";
import { signUp } from "../firebase/auth";
import Signup from "../components/auth/SignUp";

const SignupScreen: React.FC = () => {
  const [name, setName] = useState<string>("");
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");

  const handleSignUp = async () => {
    try {
      const user = await signUp(name, email, password);
      console.log("Signed up:", user);
    } catch (error: any) {
      console.error(error.message);
    }
  };

  return (
    <Signup></Signup>
  );
};

export default SignupScreen;
