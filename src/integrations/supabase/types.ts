export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      backup_history: {
        Row: {
          backup_job_id: string
          backup_type: string
          checksum: string | null
          created_at: string | null
          file_size_bytes: number | null
          id: string
          table_name: string
          user_id: string
        }
        Insert: {
          backup_job_id: string
          backup_type: string
          checksum?: string | null
          created_at?: string | null
          file_size_bytes?: number | null
          id?: string
          table_name: string
          user_id: string
        }
        Update: {
          backup_job_id?: string
          backup_type?: string
          checksum?: string | null
          created_at?: string | null
          file_size_bytes?: number | null
          id?: string
          table_name?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "backup_history_backup_job_id_fkey"
            columns: ["backup_job_id"]
            isOneToOne: false
            referencedRelation: "backup_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "backup_history_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      backup_jobs: {
        Row: {
          created_at: string | null
          id: string
          status: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          status: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "backup_jobs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      backup_settings: {
        Row: {
          auto_backup_enabled: boolean
          backup_frequency: string
          created_at: string | null
          id: string
          last_backup_date: string | null
          retention_days: number
          user_id: string
        }
        Insert: {
          auto_backup_enabled?: boolean
          backup_frequency?: string
          created_at?: string | null
          id?: string
          last_backup_date?: string | null
          retention_days?: number
          user_id: string
        }
        Update: {
          auto_backup_enabled?: boolean
          backup_frequency?: string
          created_at?: string | null
          id?: string
          last_backup_date?: string | null
          retention_days?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "backup_settings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      birds: {
        Row: {
          birth_date: string | null
          color: string | null
          created_at: string | null
          father_id: string | null
          gender: string | null
          health_notes: string | null
          id: string
          mother_id: string | null
          name: string | null
          photo_url: string | null
          ring_number: string | null
          status: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          birth_date?: string | null
          color?: string | null
          created_at?: string | null
          father_id?: string | null
          gender?: string | null
          health_notes?: string | null
          id?: string
          mother_id?: string | null
          name?: string | null
          photo_url?: string | null
          ring_number?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          birth_date?: string | null
          color?: string | null
          created_at?: string | null
          father_id?: string | null
          gender?: string | null
          health_notes?: string | null
          id?: string
          mother_id?: string | null
          name?: string | null
          photo_url?: string | null
          ring_number?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "birds_father_id_fkey"
            columns: ["father_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "birds_mother_id_fkey"
            columns: ["mother_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "birds_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      calendar: {
        Row: {
          color: string | null
          created_at: string | null
          date: string | null
          description: string | null
          icon: string | null
          id: string
          title: string | null
          type: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          color?: string | null
          created_at?: string | null
          date?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          title?: string | null
          type?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          color?: string | null
          created_at?: string | null
          date?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          title?: string | null
          type?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "calendar_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      chicks: {
        Row: {
          birth_date: string | null
          color: string | null
          created_at: string | null
          egg_id: string | null
          egg_number: number | null
          father_id: string | null
          gender: string | null
          hatch_date: string | null
          health_notes: string | null
          id: string
          incubation_id: string | null
          mother_id: string | null
          name: string | null
          photo_url: string | null
          ring_number: string | null
          status: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          birth_date?: string | null
          color?: string | null
          created_at?: string | null
          egg_id?: string | null
          egg_number?: number | null
          father_id?: string | null
          gender?: string | null
          hatch_date?: string | null
          health_notes?: string | null
          id?: string
          incubation_id?: string | null
          mother_id?: string | null
          name?: string | null
          photo_url?: string | null
          ring_number?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          birth_date?: string | null
          color?: string | null
          created_at?: string | null
          egg_id?: string | null
          egg_number?: number | null
          father_id?: string | null
          gender?: string | null
          hatch_date?: string | null
          health_notes?: string | null
          id?: string
          incubation_id?: string | null
          mother_id?: string | null
          name?: string | null
          photo_url?: string | null
          ring_number?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chicks_egg_id_fkey"
            columns: ["egg_id"]
            isOneToOne: false
            referencedRelation: "eggs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chicks_father_id_fkey"
            columns: ["father_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chicks_incubation_id_fkey"
            columns: ["incubation_id"]
            isOneToOne: false
            referencedRelation: "incubations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chicks_mother_id_fkey"
            columns: ["mother_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chicks_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      clutches: {
        Row: {
          created_at: string | null
          female_bird_id: string | null
          id: string
          male_bird_id: string | null
          name: string | null
          notes: string | null
          pair_date: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name?: string | null
          notes?: string | null
          pair_date?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name?: string | null
          notes?: string | null
          pair_date?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "clutches_female_bird_id_fkey"
            columns: ["female_bird_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clutches_male_bird_id_fkey"
            columns: ["male_bird_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clutches_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      eggs: {
        Row: {
          clutch_id: string | null
          created_at: string | null
          egg_number: number | null
          hatch_date: string | null
          id: string
          incubation_id: string | null
          is_deleted: boolean | null
          notes: string | null
          start_date: string | null
          status: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          clutch_id?: string | null
          created_at?: string | null
          egg_number?: number | null
          hatch_date?: string | null
          id?: string
          incubation_id?: string | null
          is_deleted?: boolean | null
          notes?: string | null
          start_date?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          clutch_id?: string | null
          created_at?: string | null
          egg_number?: number | null
          hatch_date?: string | null
          id?: string
          incubation_id?: string | null
          is_deleted?: boolean | null
          notes?: string | null
          start_date?: string | null
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "eggs_clutch_id_fkey"
            columns: ["clutch_id"]
            isOneToOne: false
            referencedRelation: "clutches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "eggs_incubation_id_fkey"
            columns: ["incubation_id"]
            isOneToOne: false
            referencedRelation: "incubations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "eggs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      incubations: {
        Row: {
          created_at: string | null
          enable_notifications: boolean | null
          female_bird_id: string | null
          id: string
          male_bird_id: string | null
          name: string | null
          notes: string | null
          start_date: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          enable_notifications?: boolean | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name?: string | null
          notes?: string | null
          start_date?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          enable_notifications?: boolean | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name?: string | null
          notes?: string | null
          start_date?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "incubations_female_bird_id_fkey"
            columns: ["female_bird_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incubations_male_bird_id_fkey"
            columns: ["male_bird_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incubations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      notification_interactions: {
        Row: {
          action: string
          id: string
          metadata: Json | null
          notification_id: string
          timestamp: string | null
          user_id: string
        }
        Insert: {
          action: string
          id?: string
          metadata?: Json | null
          notification_id: string
          timestamp?: string | null
          user_id: string
        }
        Update: {
          action?: string
          id?: string
          metadata?: Json | null
          notification_id?: string
          timestamp?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_interactions_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "user_notification_tokens"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_interactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          email: string | null
          full_name: string | null
          id: string
          updated_at: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id: string
          updated_at?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      security_events: {
        Row: {
          created_at: string | null
          event_type: string | null
          id: string
          ip_address: string | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          event_type?: string | null
          id?: string
          ip_address?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          event_type?: string | null
          id?: string
          ip_address?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "security_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      temperature_readings: {
        Row: {
          created_at: string | null
          humidity: number | null
          id: string
          sensor_id: string
          temperature: number
          timestamp: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          humidity?: number | null
          id?: string
          sensor_id: string
          temperature: number
          timestamp?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          humidity?: number | null
          id?: string
          sensor_id?: string
          temperature?: number
          timestamp?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "temperature_readings_sensor_id_fkey"
            columns: ["sensor_id"]
            isOneToOne: false
            referencedRelation: "temperature_sensors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temperature_readings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      temperature_sensors: {
        Row: {
          created_at: string | null
          humidity_tolerance: number | null
          id: string
          is_active: boolean | null
          name: string
          target_humidity: number | null
          target_temp: number
          temp_tolerance: number
          type: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          humidity_tolerance?: number | null
          id?: string
          is_active?: boolean | null
          name: string
          target_humidity?: number | null
          target_temp: number
          temp_tolerance: number
          type: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          humidity_tolerance?: number | null
          id?: string
          is_active?: boolean | null
          name?: string
          target_humidity?: number | null
          target_temp?: number
          temp_tolerance?: number
          type?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "temperature_sensors_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      todos: {
        Row: {
          completed: boolean | null
          created_at: string | null
          description: string | null
          id: string
          title: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          completed?: boolean | null
          created_at?: string | null
          description?: string | null
          id?: string
          title?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          completed?: boolean | null
          created_at?: string | null
          description?: string | null
          id?: string
          title?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "todos_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      user_notification_settings: {
        Row: {
          created_at: string | null
          do_not_disturb_end: string | null
          do_not_disturb_start: string | null
          egg_turning_enabled: boolean | null
          egg_turning_interval: number | null
          feeding_interval: number | null
          feeding_reminders_enabled: boolean | null
          humidity_alerts_enabled: boolean | null
          humidity_max: number | null
          humidity_min: number | null
          id: string
          language: string | null
          sound_enabled: boolean | null
          temperature_alerts_enabled: boolean | null
          temperature_max: number | null
          temperature_min: number | null
          temperature_tolerance: number | null
          updated_at: string | null
          user_id: string | null
          vibration_enabled: boolean | null
        }
        Insert: {
          created_at?: string | null
          do_not_disturb_end?: string | null
          do_not_disturb_start?: string | null
          egg_turning_enabled?: boolean | null
          egg_turning_interval?: number | null
          feeding_interval?: number | null
          feeding_reminders_enabled?: boolean | null
          humidity_alerts_enabled?: boolean | null
          humidity_max?: number | null
          humidity_min?: number | null
          id?: string
          language?: string | null
          sound_enabled?: boolean | null
          temperature_alerts_enabled?: boolean | null
          temperature_max?: number | null
          temperature_min?: number | null
          temperature_tolerance?: number | null
          updated_at?: string | null
          user_id?: string | null
          vibration_enabled?: boolean | null
        }
        Update: {
          created_at?: string | null
          do_not_disturb_end?: string | null
          do_not_disturb_start?: string | null
          egg_turning_enabled?: boolean | null
          egg_turning_interval?: number | null
          feeding_interval?: number | null
          feeding_reminders_enabled?: boolean | null
          humidity_alerts_enabled?: boolean | null
          humidity_max?: number | null
          humidity_min?: number | null
          id?: string
          language?: string | null
          sound_enabled?: boolean | null
          temperature_alerts_enabled?: boolean | null
          temperature_max?: number | null
          temperature_min?: number | null
          temperature_tolerance?: number | null
          updated_at?: string | null
          user_id?: string | null
          vibration_enabled?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "user_notification_settings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      user_notification_tokens: {
        Row: {
          created_at: string | null
          device_info: Json | null
          id: string
          is_active: boolean | null
          platform: string | null
          token: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform?: string | null
          token?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform?: string | null
          token?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_notification_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
