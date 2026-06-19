import * as React from "react"
import { cn } from "@/lib/utils"
import { cva } from "class-variance-authority"

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-layer-0",
        secondary: "border-transparent bg-layer-2 text-text-200",
        destructive: "border-transparent bg-danger text-layer-0",
        outline: "text-text-200",
        success: "border-transparent bg-success text-layer-0",
        warning: "border-transparent bg-warning text-layer-0",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

function Badge({ className, variant, ...props }) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }
