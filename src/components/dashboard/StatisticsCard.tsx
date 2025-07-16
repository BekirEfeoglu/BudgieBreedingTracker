import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LucideIcon } from 'lucide-react';

interface StatisticItemProps {
  value: number | string | React.ReactNode;
  label: string;
  icon?: LucideIcon;
  iconColor?: string;
  bgColor?: string;
  textColor?: string;
  borderColor?: string;
  className?: string;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
  subtitle?: string;
}

interface StatisticsCardProps {
  title: string;
  icon: React.ReactNode;
  iconLabel: string;
  gradient: string;
  children: React.ReactNode;
  className?: string;
}

const StatisticItem: React.FC<StatisticItemProps> = ({
  value,
  label,
  icon: Icon,
  iconColor = "text-primary",
  bgColor = "bg-card",
  textColor = "text-foreground",
  borderColor = "border-border",
  className = "",
  trend,
  trendValue,
  subtitle
}) => (
  <div className={`group relative overflow-hidden rounded-xl border ${borderColor} ${bgColor} p-3 transition-all duration-300 hover:shadow-lg ${className}`}>
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 min-w-0 flex-1">
          {Icon && <Icon className={`w-4 h-4 ${iconColor} flex-shrink-0`} />}
          <span className="text-xs font-medium text-muted-foreground truncate">{label}</span>
        </div>
        {trend && trendValue && (
          <div className={`flex items-center gap-1 text-xs font-medium flex-shrink-0 ${
            trend === 'up' ? 'text-green-600' : 
            trend === 'down' ? 'text-red-600' : 
            'text-gray-600'
          }`}>
            <span>{trend === 'up' ? '↗' : trend === 'down' ? '↘' : '→'}</span>
            <span className="hidden sm:inline">{trendValue}</span>
          </div>
        )}
      </div>
      <div className={`text-xl sm:text-2xl font-bold ${textColor} leading-none`}>{value}</div>
      {subtitle && <p className="text-xs text-muted-foreground leading-tight break-words">{subtitle}</p>}
    </div>
    <div className="absolute inset-0 bg-gradient-to-br from-transparent via-transparent to-primary/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
  </div>
);

const StatisticsCard: React.FC<StatisticsCardProps> = ({
  title,
  icon,
  iconLabel,
  gradient,
  children,
  className = ""
}) => (
  <Card className={`overflow-hidden shadow-lg border-0 w-full ${className}`}>
    <CardHeader className={`pb-3 ${gradient}`}>
      <CardTitle className="flex items-center justify-center gap-2 text-white text-center">
        <div className="w-8 h-8 bg-white/20 backdrop-blur-sm rounded-lg flex items-center justify-center border border-white/30 flex-shrink-0">
          <span className="text-base" role="img" aria-label={iconLabel}>{icon}</span>
        </div>
        <span className="font-semibold text-sm leading-tight">{title}</span>
      </CardTitle>
    </CardHeader>
    <CardContent className="p-3 bg-card/50 backdrop-blur-sm">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {children}
      </div>
    </CardContent>
  </Card>
);

export { StatisticsCard, StatisticItem };