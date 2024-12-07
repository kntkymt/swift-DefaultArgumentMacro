@attached(extension, names: arbitrary)
public macro DefaultArgument(funcName: String, defaultValues: [String: Any]) = #externalMacro(module: "DefaultArgumentMacro", type: "DefaultArgument")
