#!/usr/bin/env node

/**
 * Supabase Yapılandırma Test Scripti
 * Bu script Supabase yapılandırmanızı kapsamlı bir şekilde test eder
 */

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSection(title) {
  log(`\n${'='.repeat(50)}`, 'cyan');
  log(` ${title}`, 'bright');
  log(`${'='.repeat(50)}`, 'cyan');
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️ ${message}`, 'yellow');
}

function logInfo(message) {
  log(`ℹ️ ${message}`, 'blue');
}

// Test results
const testResults = {
  passed: 0,
  failed: 0,
  warnings: 0,
  tests: []
};

function addTestResult(test, passed, message, details = null) {
  const result = {
    test,
    passed,
    message,
    details,
    timestamp: new Date().toISOString()
  };
  
  testResults.tests.push(result);
  
  if (passed) {
    testResults.passed++;
    logSuccess(`${test}: ${message}`);
  } else {
    testResults.failed++;
    logError(`${test}: ${message}`);
    if (details) {
      logError(`   Detay: ${details}`);
    }
  }
}

function addWarning(test, message) {
  testResults.warnings++;
  logWarning(`${test}: ${message}`);
}

// Configuration validation
function validateConfig() {
  logSection('Yapılandırma Doğrulama');
  
  // Check environment variables
  const requiredEnvVars = [
    'NEXT_PUBLIC_SUPABASE_URL',
    'NEXT_PUBLIC_SUPABASE_ANON_KEY'
  ];
  
  const optionalEnvVars = [
    'SMTP_HOST',
    'SMTP_PORT',
    'SMTP_USERNAME',
    'SMTP_PASSWORD',
    'RESEND_API_KEY'
  ];
  
  // Check required env vars
  requiredEnvVars.forEach(envVar => {
    if (process.env[envVar]) {
      addTestResult(
        `Environment Variable: ${envVar}`,
        true,
        'Mevcut'
      );
    } else {
      addTestResult(
        `Environment Variable: ${envVar}`,
        false,
        'Eksik',
        'Bu değişken gerekli'
      );
    }
  });
  
  // Check optional env vars
  optionalEnvVars.forEach(envVar => {
    if (process.env[envVar]) {
      addTestResult(
        `Optional Environment Variable: ${envVar}`,
        true,
        'Mevcut'
      );
    } else {
      addWarning(
        `Optional Environment Variable: ${envVar}`,
        'Eksik (opsiyonel)'
      );
    }
  });
  
  // Check config files
  const configFiles = [
    'supabase/config.toml',
    'src/integrations/supabase/client.ts',
    'src/integrations/supabase/types.ts'
  ];
  
  configFiles.forEach(file => {
    if (fs.existsSync(file)) {
      addTestResult(
        `Config File: ${file}`,
        true,
        'Mevcut'
      );
    } else {
      addTestResult(
        `Config File: ${file}`,
        false,
        'Eksik',
        'Bu dosya gerekli'
      );
    }
  });
}

// Supabase connection test
async function testSupabaseConnection() {
  logSection('Supabase Bağlantı Testi');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    addTestResult(
      'Supabase Connection',
      false,
      'Bağlantı bilgileri eksik',
      'URL ve API key gerekli'
    );
    return;
  }
  
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Test basic connection
    const { data, error } = await supabase
      .from('profiles')
      .select('id')
      .limit(1);
    
    if (error) {
      addTestResult(
        'Supabase Connection',
        false,
        'Bağlantı hatası',
        error.message
      );
    } else {
      addTestResult(
        'Supabase Connection',
        true,
        'Bağlantı başarılı'
      );
    }
    
    // Test auth
    const { data: { session }, error: authError } = await supabase.auth.getSession();
    
    if (authError) {
      addTestResult(
        'Supabase Auth',
        false,
        'Auth hatası',
        authError.message
      );
    } else {
      addTestResult(
        'Supabase Auth',
        true,
        'Auth çalışıyor'
      );
    }
    
  } catch (error) {
    addTestResult(
      'Supabase Connection',
      false,
      'Bağlantı hatası',
      error.message
    );
  }
}

// Database schema validation
async function validateDatabaseSchema() {
  logSection('Veritabanı Şeması Doğrulama');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    addTestResult(
      'Database Schema',
      false,
      'Bağlantı bilgileri eksik'
    );
    return;
  }
  
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Check required tables
    const requiredTables = [
      'profiles',
      'birds',
      'chicks',
      'eggs',
      'incubations',
      'clutches',
      'calendar',
      'user_notification_settings',
      'user_notification_tokens'
    ];
    
    for (const table of requiredTables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('*')
          .limit(1);
        
        if (error) {
          addTestResult(
            `Table: ${table}`,
            false,
            'Tablo erişim hatası',
            error.message
          );
        } else {
          addTestResult(
            `Table: ${table}`,
            true,
            'Tablo mevcut ve erişilebilir'
          );
        }
      } catch (error) {
        addTestResult(
          `Table: ${table}`,
          false,
          'Tablo test hatası',
          error.message
        );
      }
    }
    
  } catch (error) {
    addTestResult(
      'Database Schema',
      false,
      'Şema doğrulama hatası',
      error.message
    );
  }
}

// RLS policies validation
async function validateRLSPolicies() {
  logSection('RLS Politikaları Doğrulama');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    addTestResult(
      'RLS Policies',
      false,
      'Bağlantı bilgileri eksik'
    );
    return;
  }
  
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Test RLS by trying to access data without auth
    const { data, error } = await supabase
      .from('birds')
      .select('*')
      .limit(1);
    
    if (error && error.code === 'PGRST116') {
      addTestResult(
        'RLS Policies',
        true,
        'RLS politikaları aktif ve çalışıyor'
      );
    } else if (data && data.length > 0) {
      addWarning(
        'RLS Policies',
        'RLS politikaları aktif olmayabilir - veri erişilebilir'
      );
    } else {
      addTestResult(
        'RLS Policies',
        true,
        'RLS politikaları çalışıyor (veri erişilemez)'
      );
    }
    
  } catch (error) {
    addTestResult(
      'RLS Policies',
      false,
      'RLS test hatası',
      error.message
    );
  }
}

// Migration files validation
function validateMigrationFiles() {
  logSection('Migration Dosyaları Doğrulama');
  
  const migrationsDir = 'supabase/migrations';
  
  if (!fs.existsSync(migrationsDir)) {
    addTestResult(
      'Migration Directory',
      false,
      'Migration klasörü eksik'
    );
    return;
  }
  
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();
  
  if (migrationFiles.length === 0) {
    addTestResult(
      'Migration Files',
      false,
      'Migration dosyası bulunamadı'
    );
    return;
  }
  
  addTestResult(
    'Migration Files',
    true,
    `${migrationFiles.length} migration dosyası bulundu`
  );
  
  // Check for potential issues in migration files
  migrationFiles.forEach(file => {
    const filePath = path.join(migrationsDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check for common issues
    if (content.includes('auth.uid()') && !content.includes('(SELECT auth.uid())')) {
      addWarning(
        `Migration: ${file}`,
        'auth.uid() optimize edilmemiş olabilir'
      );
    }
    
    if (content.includes('CREATE INDEX') && content.includes('IF NOT EXISTS')) {
      addTestResult(
        `Migration: ${file}`,
        true,
        'İndeks oluşturma güvenli'
      );
    }
  });
}

// Performance validation
async function validatePerformance() {
  logSection('Performans Doğrulama');
  
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    addTestResult(
      'Performance Test',
      false,
      'Bağlantı bilgileri eksik'
    );
    return;
  }
  
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Test query performance
    const startTime = Date.now();
    const { data, error } = await supabase
      .from('birds')
      .select('id, name')
      .limit(10);
    
    const endTime = Date.now();
    const queryTime = endTime - startTime;
    
    if (error) {
      addTestResult(
        'Query Performance',
        false,
        'Sorgu hatası',
        error.message
      );
    } else {
      if (queryTime < 1000) {
        addTestResult(
          'Query Performance',
          true,
          `Sorgu hızlı (${queryTime}ms)`
        );
      } else {
        addWarning(
          'Query Performance',
          `Sorgu yavaş (${queryTime}ms)`
        );
      }
    }
    
  } catch (error) {
    addTestResult(
      'Performance Test',
      false,
      'Performans test hatası',
      error.message
    );
  }
}

// Generate report
function generateReport() {
  logSection('Test Raporu');
  
  log(`Toplam Test: ${testResults.tests.length}`, 'bright');
  log(`✅ Başarılı: ${testResults.passed}`, 'green');
  log(`❌ Başarısız: ${testResults.failed}`, 'red');
  log(`⚠️ Uyarı: ${testResults.warnings}`, 'yellow');
  
  const successRate = ((testResults.passed / testResults.tests.length) * 100).toFixed(1);
  log(`\nBaşarı Oranı: ${successRate}%`, 'bright');
  
  if (testResults.failed === 0) {
    log('\n🎉 Tüm testler başarılı!', 'green');
  } else {
    log('\n🔧 Bazı sorunlar tespit edildi. Yukarıdaki hataları düzeltin.', 'red');
  }
  
  // Save detailed report
  const reportPath = 'supabase-test-report.json';
  fs.writeFileSync(reportPath, JSON.stringify(testResults, null, 2));
  log(`\n📄 Detaylı rapor kaydedildi: ${reportPath}`, 'blue');
}

// Main function
async function main() {
  log('🚀 Supabase Yapılandırma Testi Başlatılıyor...', 'bright');
  
  try {
    validateConfig();
    await testSupabaseConnection();
    await validateDatabaseSchema();
    await validateRLSPolicies();
    validateMigrationFiles();
    await validatePerformance();
    generateReport();
  } catch (error) {
    logError(`Test sırasında hata oluştu: ${error.message}`);
    process.exit(1);
  }
}

// Run the main function
main().catch(error => {
  logError(`Ana fonksiyon hatası: ${error.message}`);
  process.exit(1);
});

export {
  validateConfig,
  testSupabaseConnection,
  validateDatabaseSchema,
  validateRLSPolicies,
  validateMigrationFiles,
  validatePerformance,
  generateReport
}; 