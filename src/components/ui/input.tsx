import * as React from "react"

import { cn } from "@/lib/utils"

const Input = React.forwardRef<HTMLInputElement, React.ComponentProps<"input">>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
          // Mobil uyumluluk için ek stiller
          "text-gray-900 bg-white",
          // iOS Safari için özel stiller
          "[-webkit-appearance:none] [-webkit-tap-highlight-color:transparent]",
          // Android için özel stiller
          "[-webkit-text-fill-color:currentColor]",
          className
        )}
        style={{
          // Mobil tarayıcılar için ek güvenlik
          color: '#111827 !important', // text-gray-900
          backgroundColor: '#ffffff !important',
          WebkitTextFillColor: '#111827 !important',
          WebkitAppearance: 'none',
          MozAppearance: 'textfield',
          appearance: 'none',
          // iOS Safari için özel düzeltme
          caretColor: '#111827 !important',
          // Mobil tarayıcılar için ek güvenlik
          fontSize: '16px !important',
          WebkitTapHighlightColor: 'transparent',
          WebkitUserSelect: 'text',
          MozUserSelect: 'text',
          msUserSelect: 'text',
          userSelect: 'text'
        }}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }
