import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium ring-offset-layer-0 transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-amber text-[#0B0F1A] font-bold shadow-[0_0_0_0_var(--amber-glow)] hover:shadow-[0_0_20px_var(--amber-glow)] hover:-translate-y-[1px] active:translate-y-0 active:brightness-95",
        destructive: "bg-error text-white hover:bg-error/90 shadow-sm",
        outline: "bg-transparent text-text-200 border border-border-strong hover:border-amber-border hover:text-text-100 hover:bg-amber-dim",
        secondary: "bg-transparent text-text-200 border border-border-strong hover:border-amber-border hover:text-text-100 hover:bg-amber-dim",
        ghost: "bg-transparent text-text-300 border-none hover:text-text-100 hover:bg-layer-2",
        link: "text-amber underline-offset-4 hover:underline",
        success: "bg-success text-white hover:bg-success/90 shadow-sm",
        warning: "bg-warning text-[#0B0F1A] hover:bg-warning/90 shadow-sm font-bold",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-lg px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Button = React.forwardRef(({ className, variant, size, asChild = false, ...props }, ref) => {
  const Comp = asChild ? Slot : "button"
  return (
    <Comp
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      {...props}
    />
  )
})
Button.displayName = "Button"

export { Button, buttonVariants }
