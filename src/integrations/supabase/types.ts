export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
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
        ]
      }
      backup_jobs: {
        Row: {
          backup_type: string
          completed_at: string | null
          created_at: string | null
          error_message: string | null
          file_path: string | null
          id: string
          record_count: number | null
          status: string
          table_name: string
          user_id: string
        }
        Insert: {
          backup_type: string
          completed_at?: string | null
          created_at?: string | null
          error_message?: string | null
          file_path?: string | null
          id?: string
          record_count?: number | null
          status?: string
          table_name: string
          user_id: string
        }
        Update: {
          backup_type?: string
          completed_at?: string | null
          created_at?: string | null
          error_message?: string | null
          file_path?: string | null
          id?: string
          record_count?: number | null
          status?: string
          table_name?: string
          user_id?: string
        }
        Relationships: []
      }
      backup_settings: {
        Row: {
          auto_backup_enabled: boolean | null
          backup_frequency_hours: number | null
          created_at: string | null
          id: string
          retention_days: number | null
          tables_to_backup: string[] | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          auto_backup_enabled?: boolean | null
          backup_frequency_hours?: number | null
          created_at?: string | null
          id?: string
          retention_days?: number | null
          tables_to_backup?: string[] | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          auto_backup_enabled?: boolean | null
          backup_frequency_hours?: number | null
          created_at?: string | null
          id?: string
          retention_days?: number | null
          tables_to_backup?: string[] | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
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
          name: string
          photo_url: string | null
          ring_number: string | null
          updated_at: string | null
          user_id: string
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
          name: string
          photo_url?: string | null
          ring_number?: string | null
          updated_at?: string | null
          user_id: string
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
          name?: string
          photo_url?: string | null
          ring_number?: string | null
          updated_at?: string | null
          user_id?: string
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
        ]
      }
      calendar: {
        Row: {
          created_at: string | null
          description: string | null
          event_date: string
          event_type: string | null
          id: string
          related_bird_id: string | null
          related_chick_id: string | null
          related_clutch_id: string | null
          related_egg_id: string | null
          title: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          event_date: string
          event_type?: string | null
          id?: string
          related_bird_id?: string | null
          related_chick_id?: string | null
          related_clutch_id?: string | null
          related_egg_id?: string | null
          title: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          description?: string | null
          event_date?: string
          event_type?: string | null
          id?: string
          related_bird_id?: string | null
          related_chick_id?: string | null
          related_clutch_id?: string | null
          related_egg_id?: string | null
          title?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "calendar_related_bird_id_fkey"
            columns: ["related_bird_id"]
            isOneToOne: false
            referencedRelation: "birds"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_related_chick_id_fkey"
            columns: ["related_chick_id"]
            isOneToOne: false
            referencedRelation: "chicks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_related_clutch_id_fkey"
            columns: ["related_clutch_id"]
            isOneToOne: false
            referencedRelation: "clutches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_related_egg_id_fkey"
            columns: ["related_egg_id"]
            isOneToOne: false
            referencedRelation: "eggs"
            referencedColumns: ["id"]
          },
        ]
      }
      chicks: {
        Row: {
          clutch_id: string | null
          color: string | null
          created_at: string | null
          egg_id: string | null
          father_id: string | null
          gender: string | null
          hatch_date: string
          health_notes: string | null
          id: string
          incubation_id: string
          mother_id: string | null
          name: string
          photo_url: string | null
          ring_number: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          clutch_id?: string | null
          color?: string | null
          created_at?: string | null
          egg_id?: string | null
          father_id?: string | null
          gender?: string | null
          hatch_date: string
          health_notes?: string | null
          id?: string
          incubation_id: string
          mother_id?: string | null
          name: string
          photo_url?: string | null
          ring_number?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          clutch_id?: string | null
          color?: string | null
          created_at?: string | null
          egg_id?: string | null
          father_id?: string | null
          gender?: string | null
          hatch_date?: string
          health_notes?: string | null
          id?: string
          incubation_id?: string
          mother_id?: string | null
          name?: string
          photo_url?: string | null
          ring_number?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chicks_clutch_id_fkey"
            columns: ["clutch_id"]
            isOneToOne: false
            referencedRelation: "clutches"
            referencedColumns: ["id"]
          },
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
        ]
      }
      clutches: {
        Row: {
          created_at: string | null
          expected_hatch_date: string | null
          female_bird_id: string | null
          id: string
          last_modified: string | null
          male_bird_id: string | null
          nest_name: string
          notes: string | null
          pair_date: string
          sync_version: number | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          expected_hatch_date?: string | null
          female_bird_id?: string | null
          id?: string
          last_modified?: string | null
          male_bird_id?: string | null
          nest_name: string
          notes?: string | null
          pair_date: string
          sync_version?: number | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          expected_hatch_date?: string | null
          female_bird_id?: string | null
          id?: string
          last_modified?: string | null
          male_bird_id?: string | null
          nest_name?: string
          notes?: string | null
          pair_date?: string
          sync_version?: number | null
          updated_at?: string | null
          user_id?: string
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
        ]
      }
      eggs: {
        Row: {
          chick_id: string | null
          created_at: string | null
          hatch_date: string | null
          id: string
          incubation_id: string
          lay_date: string
          notes: string | null
          number: number | null
          status: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          chick_id?: string | null
          created_at?: string | null
          hatch_date?: string | null
          id?: string
          incubation_id: string
          lay_date: string
          notes?: string | null
          number?: number | null
          status?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          chick_id?: string | null
          created_at?: string | null
          hatch_date?: string | null
          id?: string
          incubation_id?: string
          lay_date?: string
          notes?: string | null
          number?: number | null
          status?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "eggs_incubation_id_fkey"
            columns: ["incubation_id"]
            isOneToOne: false
            referencedRelation: "incubations"
            referencedColumns: ["id"]
          },
        ]
      }
      incubations: {
        Row: {
          created_at: string | null
          female_bird_id: string | null
          id: string
          male_bird_id: string | null
          name: string
          notes: string | null
          start_date: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name: string
          notes?: string | null
          start_date: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          female_bird_id?: string | null
          id?: string
          male_bird_id?: string | null
          name?: string
          notes?: string | null
          start_date?: string
          updated_at?: string | null
          user_id?: string
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
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          first_name: string | null
          id: string
          last_name: string | null
          updated_at: string | null
        }
        Insert: {
          avatar_url?: string | null
          first_name?: string | null
          id: string
          last_name?: string | null
          updated_at?: string | null
        }
        Update: {
          avatar_url?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      security_events: {
        Row: {
          created_at: string | null
          event_type: string
          id: string
          ip_address: unknown | null
          metadata: Json | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          event_type: string
          id?: string
          ip_address?: unknown | null
          metadata?: Json | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          event_type?: string
          id?: string
          ip_address?: unknown | null
          metadata?: Json | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: []
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
          user_id: string
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
          user_id: string
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
          user_id?: string
          vibration_enabled?: boolean | null
        }
        Relationships: []
      }
      user_notification_tokens: {
        Row: {
          created_at: string | null
          device_info: Json | null
          id: string
          is_active: boolean | null
          platform: string
          token: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform: string
          token: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform?: string
          token?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_optimized_backup: {
        Args: { p_user_id: string; p_backup_type?: string; p_tables?: string[] }
        Returns: string
      }
      create_user_backup: {
        Args: { p_user_id: string; p_backup_type?: string; p_tables?: string[] }
        Returns: string
      }
      get_bird_family_optimized: {
        Args: { target_bird_id: string; target_user_id: string }
        Returns: {
          relation_type: string
          bird_id: string
          bird_name: string
          bird_gender: string
          is_chick: boolean
        }[]
      }
      get_last_backup_time: {
        Args: { p_user_id: string; p_table_name: string }
        Returns: string
      }
      get_table_stats: {
        Args: { input_table_name: string }
        Returns: {
          table_name: string
          row_count: number
          total_size: string
          index_size: string
        }[]
      }
      update_backup_job_status: {
        Args: {
          p_job_id: string
          p_status: string
          p_file_path?: string
          p_record_count?: number
          p_error_message?: string
        }
        Returns: undefined
      }
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
