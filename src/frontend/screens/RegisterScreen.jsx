import { Image, StyleSheet, ScrollView } from "react-native";
import RegisterCard from "../components/RegisterCard";

export default function RegisterScreen() {
  return (
    <ScrollView
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.container}
    >
      <Image
        source={require("../assets/register-bg.png")}
        style={styles.image}
      />

      <RegisterCard />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingBottom: 40,
    backgroundColor: "#fff",
  },
  image: {
    width: "100%",
    height: 280,
    resizeMode: "cover",
  },
});
