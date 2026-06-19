import * as React from "react"
import { cn } from "@/lib/utils"

const Input = React.forwardRef(({ className, type, ...props }, ref) => {
  return (
    <input
      type={type}
      className={cn(
        "flex h-10 w-full rounded-lg border border-border-strong bg-layer-2 px-3 py-2 text-sm text-text-100 ring-offset-layer-0 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-text-400 focus-visible:outline-none focus-visible:border-amber focus-visible:ring-4 focus-visible:ring-amber-glow disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-200",
        className
      )}
      ref={ref}
      {...props}
    />
  )
})
Input.displayName = "Input"

export { Input }
