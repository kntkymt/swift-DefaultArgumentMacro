@attached(extension, names: arbitrary)
public macro DefaultArgument(funcName: String, defaultValues: [String: Any]) = #externalMacro(module: "DefaultArgumentMacros", type: "DefaultArgument")
