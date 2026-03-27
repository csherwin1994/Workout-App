import { StatusBar } from 'expo-status-bar';
import { Text, View, TouchableOpacity } from 'react-native';
import { useState } from 'react';

export default function App() {
  const [tab, setTab] = useState('Workout');

  const renderScreen = () => {
    if (tab === 'Workout') return <Text style={styles.title}>Workout Home</Text>;
    if (tab === 'History') return <Text style={styles.title}>History</Text>;
    if (tab === 'Exercises') return <Text style={styles.title}>Exercises</Text>;
    if (tab === 'Routines') return <Text style={styles.title}>Routines</Text>;
    if (tab === 'Profile') return <Text style={styles.title}>Profile</Text>;
  };

  return (
    <View style={styles.container}>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        {renderScreen()}
      </View>

      <View style={styles.tabBar}>
        {['Workout','History','Exercises','Routines','Profile'].map(t => (
          <TouchableOpacity key={t} onPress={() => setTab(t)}>
            <Text style={{ color: tab === t ? '#007AFF' : '#999', fontSize: 12 }}>{t}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <StatusBar style="auto" />
    </View>
  );
}

const styles = {
  container: {
    flex: 1,
    backgroundColor: '#fff'
  },
  title: {
    fontSize: 28,
    fontWeight: '600'
  },
  tabBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 12,
    borderTopWidth: 1,
    borderColor: '#eee'
  }
};