//  WHAT: The kit's files as Swift string literals: what a call writes into an app, before `TemplateRender` drops the
//        parts the call left out and fills in its words, numbers and symbols. Embedded in code so the package carries
//        no resource bundle.
//  PIN:  A TEMPLATE IS SWIFT AS A PERSON WRITES IT, with every part asked for. Its conditions are comment lines
//        (`//@if part.tips`), and what the call says is a placeholder: `{{s:welcome.title}}` a string,
//        `{{n:tip.scale}}` a number, `{{a:tip.step}}` an animation, `{{y:symbol.back}}` a symbol, `{{x:modifier}}`
//        something worked out from the whole call.

/// The kit's templates, one static string a file.
enum Template {}
