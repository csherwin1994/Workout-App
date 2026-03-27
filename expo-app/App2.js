import React, { useMemo, useState } from 'react';
import { SafeAreaView, View, Text, TouchableOpacity, ScrollView, TextInput } from 'react-native';
import { StatusBar } from 'expo-status-bar';

const theme = {
  bg: '#0B0D10',
  panel: '#12161B',
  panel2: '#171C22',
  chip: '#1D2430',
  line: '#232A35',
  text: '#F4F7FB',
  muted: '#96A0AE',
  blue: '#4DA3FF',
  blue2: '#2B7FFF',
  green: '#22C55E',
  orange: '#FF9F0A'
};

function Screen({ children }) {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.bg }}>
      <StatusBar style="light" />
      {children}
    </SafeAreaView>
  );
}

function Card({ children, style }) {
  return <View style={[{ backgroundColor: theme.panel, borderRadius: 18, padding: 16, marginBottom: 14 }, style]}>{children}</View>;
}

function WorkoutHome() {
  const routines = [
    { name: 'Push Day', exercises: 5 },
    { name: 'Pull Day', exercises: 6 },
    { name: 'Leg Day', exercises: 4 }
  ];

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 120 }}>
        <Text style={{ color: theme.text, fontSize: 32, fontWeight: '800', marginBottom: 18 }}>Workout</Text>
        <Card style={{ backgroundColor: theme.panel2, borderWidth: 1, borderColor: theme.line }}>
          <Text style={{ color: theme.muted, fontSize: 13, marginBottom: 8 }}>Today</Text>
          <Text style={{ color: theme.text, fontSize: 28, fontWeight: '800', marginBottom: 8 }}>Ready to lift?</Text>
          <Text style={{ color: theme.muted, lineHeight: 20, marginBottom: 16 }}>Start a session fast, jump into a routine, and keep the logging flow tight.</Text>
          <TouchableOpacity style={{ backgroundColor: theme.blue2, paddingVertical: 16, borderRadius: 14, marginBottom: 10 }}>
            <Text style={{ color: 'white', textAlign: 'center', fontSize: 17, fontWeight: '700' }}>Start Workout</Text>
          </TouchableOpacity>
          <TouchableOpacity style={{ backgroundColor: theme.chip, paddingVertical: 14, borderRadius: 14 }}>
            <Text style={{ color: theme.text, textAlign: 'center', fontSize: 15, fontWeight: '600' }}>Start from Routine</Text>
          </TouchableOpacity>
        </Card>
        {routines.map((routine) => (
          <Card key={routine.name} style={{ backgroundColor: theme.panel2 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
              <View>
                <Text style={{ color: theme.text, fontSize: 18, fontWeight: '700', marginBottom: 4 }}>{routine.name}</Text>
                <Text style={{ color: theme.muted }}>{routine.exercises} exercises</Text>
              </View>
              <TouchableOpacity style={{ backgroundColor: theme.blue, paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12 }}>
                <Text style={{ color: 'white', fontWeight: '700' }}>Start</Text>
              </TouchableOpacity>
            </View>
          </Card>
        ))}
      </ScrollView>
    </Screen>
  );
}

function ActiveWorkout() {
  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 120 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <Text style={{ color: '#FF5A5F', fontWeight: '700' }}>Discard</Text>
          <Text style={{ color: theme.text, fontSize: 22, fontWeight: '800' }}>Push Day</Text>
          <Text style={{ color: theme.text, fontWeight: '800' }}>Finish</Text>
        </View>
        <Card style={{ backgroundColor: theme.panel2, flexDirection: 'row', justifyContent: 'space-between' }}>
          <Text style={{ color: theme.text, fontSize: 18, fontWeight: '800' }}>05:12</Text>
          <Text style={{ color: theme.orange, fontSize: 16, fontWeight: '700' }}>Rest 01:30</Text>
        </Card>
        <Card style={{ backgroundColor: theme.panel2 }}>
          <Text style={{ color: theme.blue, fontSize: 18, fontWeight: '800', marginBottom: 4 }}>Bench Press</Text>
          <Text style={{ color: theme.muted, marginBottom: 14 }}>Chest</Text>
          <Text style={{ color: theme.text, marginBottom: 6 }}>80 kg × 8</Text>
          <Text style={{ color: theme.text, marginBottom: 6 }}>80 kg × 8</Text>
          <Text style={{ color: theme.text, marginBottom: 14 }}>75 kg × 10</Text>
          <TouchableOpacity style={{ backgroundColor: theme.chip, paddingVertical: 12, borderRadius: 12 }}>
            <Text style={{ color: theme.text, textAlign: 'center', fontWeight: '700' }}>Add Set</Text>
          </TouchableOpacity>
        </Card>
        <TouchableOpacity style={{ backgroundColor: theme.chip, paddingVertical: 16, borderRadius: 14 }}>
          <Text style={{ color: theme.text, textAlign: 'center', fontWeight: '800' }}>Add Exercise</Text>
        </TouchableOpacity>
      </ScrollView>
    </Screen>
  );
}

function SimpleScreen({ title }) {
  return (
    <Screen>
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <Text style={{ color: theme.text, fontSize: 32, fontWeight: '800', marginBottom: 12 }}>{title}</Text>
        <Text style={{ color: theme.muted, textAlign: 'center' }}>Structured screen placeholder for the Expo migration.</Text>
      </View>
    </Screen>
  );
}

function TabBar({ tab, setTab }) {
  const tabs = ['Workout', 'Active', 'History', 'Exercises', 'Routines', 'Profile'];
  return (
    <View style={{ position: 'absolute', left: 16, right: 16, bottom: 16, backgroundColor: '#0E1218', borderRadius: 20, paddingVertical: 14, paddingHorizontal: 10, flexDirection: 'row', justifyContent: 'space-between', borderWidth: 1, borderColor: theme.line }}>
      {tabs.map((t) => (
        <TouchableOpacity key={t} onPress={() => setTab(t)} style={{ paddingHorizontal: 4 }}>
          <Text style={{ color: tab === t ? theme.blue : '#6F7A88', fontSize: 12, fontWeight: '700' }}>{t}</Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

export default function App() {
  const [tab, setTab] = useState('Workout');

  const current = useMemo(() => {
    switch (tab) {
      case 'Workout':
        return <WorkoutHome />;
      case 'Active':
        return <ActiveWorkout />;
      case 'History':
        return <SimpleScreen title="History" />;
      case 'Exercises':
        return <SimpleScreen title="Exercises" />;
      case 'Routines':
        return <SimpleScreen title="Routines" />;
      case 'Profile':
        return <SimpleScreen title="Profile" />;
      default:
        return <WorkoutHome />;
    }
  }, [tab]);

  return (
    <View style={{ flex: 1, backgroundColor: theme.bg }}>
      {current}
      <TabBar tab={tab} setTab={setTab} />
    </View>
  );
}
