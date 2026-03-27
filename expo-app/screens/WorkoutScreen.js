import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { colors, spacing } from '../theme';

export default function WorkoutScreen() {
  return (
    <ScrollView style={{ flex:1, backgroundColor: colors.bg }} contentContainerStyle={{ padding: spacing.lg }}>
      <Text style={{ color: colors.text, fontSize: 28, fontWeight: '700', marginBottom: spacing.lg }}>Workout</Text>

      <TouchableOpacity style={{ backgroundColor: colors.blue2, padding: spacing.lg, borderRadius: 16, marginBottom: spacing.md }}>
        <Text style={{ color: 'white', fontSize: 18, fontWeight: '600' }}>Start Workout</Text>
      </TouchableOpacity>

      <TouchableOpacity style={{ backgroundColor: colors.panel, padding: spacing.lg, borderRadius: 16, marginBottom: spacing.xl }}>
        <Text style={{ color: colors.text, fontSize: 16 }}>Start from Routine</Text>
      </TouchableOpacity>

      <Text style={{ color: colors.muted, marginBottom: spacing.sm }}>Your Routines</Text>

      {['Push Day','Pull Day','Leg Day'].map((r,i)=> (
        <View key={i} style={{ backgroundColor: colors.panel2, padding: spacing.lg, borderRadius: 16, marginBottom: spacing.md, flexDirection:'row', justifyContent:'space-between', alignItems:'center' }}>
          <View>
            <Text style={{ color: colors.text, fontSize:16, fontWeight:'600' }}>{r}</Text>
            <Text style={{ color: colors.muted, fontSize:12 }}>5 exercises</Text>
          </View>
          <TouchableOpacity style={{ backgroundColor: colors.blue, paddingHorizontal:12, paddingVertical:6, borderRadius:10 }}>
            <Text style={{ color:'white' }}>Start</Text>
          </TouchableOpacity>
        </View>
      ))}
    </ScrollView>
  );
}