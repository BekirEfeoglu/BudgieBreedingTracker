
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md font-semibold ring-offset-background transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 touch-manipulation",
  {
    variants: {
      variant: {
        default: "enhanced-button-primary min-h-[44px] min-w-[44px]",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90 enhanced-button min-h-[44px] min-w-[44px]",
        outline:
          "enhanced-button-secondary border-2 border-border bg-background hover:bg-accent hover:text-accent-foreground min-h-[44px] min-w-[44px]",
        secondary:
          "enhanced-button-secondary min-h-[44px] min-w-[44px]",
        ghost: "hover:bg-accent hover:text-accent-foreground enhanced-button min-h-[44px] min-w-[44px]",
        link: "text-primary underline-offset-4 hover:underline font-medium",
      },
      size: {
        default: "h-12 px-6 py-3 text-sm min-h-[48px]",
        sm: "h-10 rounded-md px-4 text-sm min-h-[44px]",
        lg: "h-14 rounded-md px-8 text-base min-h-[56px]",
        icon: "h-12 w-12 min-h-[48px] min-w-[48px]",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
