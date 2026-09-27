import Foundation

/// Provides bilingual Greek/English and Greeklish search matching.
///
/// Supports bidirectional search so Greek queries find Latin station names (e.g. "Κοσμοραδιο" finds "Cosmoradio")
/// and Latin queries find Greek station names (e.g. "Cosmoradio" finds "Κοσμοράδιο"), with diacritic insensitivity,
/// soft/hard C handling, phonetic sound folding, and multi-word token matching.
enum GreekSearchMatcher {
    
    // MARK: - Public API
    
    /// Precomputes a search corpus containing multiple script representations for the given text.
    static func searchCorpus(for text: String) -> [String] {
        let raw = stripAccentsAndLowercase(text)
        guard !raw.isEmpty else { return [] }
        
        let greek = latinToGreek(raw)
        let latin = greekToLatin(raw)
        let latinWithC = latin.replacingOccurrences(of: "k", with: "c")
        let phonetic = phoneticKey(raw)
        
        var seen = Set<String>()
        var corpus: [String] = []
        
        for candidate in [raw, greek, latin, latinWithC, phonetic] where !candidate.isEmpty {
            if seen.insert(candidate).inserted {
                corpus.append(candidate)
            }
        }
        
        return corpus
    }
    
    /// Checks whether the search query matches the target text.
    static func matches(query: String, in target: String) -> Bool {
        let corpus = searchCorpus(for: target)
        return matches(query: query, inCorpus: corpus)
    }
    
    /// Checks whether the search query matches the precomputed search corpus.
    static func matches(query: String, inCorpus corpus: [String]) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard !corpus.isEmpty else { return false }
        
        let tokens = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return true }
        
        return tokens.allSatisfy { token in
            matchesToken(token, inCorpus: corpus)
        }
    }
    
    // MARK: - Normalization & Transliteration
    
    /// Strips accents/diacritics (including Greek tonos and dialytika), converts terminal sigmas, and lowercases.
    static func stripAccentsAndLowercase(_ text: String) -> String {
        let lower = text.lowercased()
        
        var result = ""
        result.reserveCapacity(lower.count)
        
        for char in lower {
            switch char {
            case "ά", "ὰ", "ᾶ", "ἀ", "ἁ", "ἂ", "ἃ", "ἄ", "ἅ", "ἆ", "ἇ":
                result.append("α")
            case "έ", "ὲ", "ἐ", "ἑ", "ἒ", "ἓ", "ἔ", "ἕ":
                result.append("ε")
            case "ή", "ὴ", "ῆ", "ἠ", "ἡ", "ἢ", "ἣ", "ἤ", "ἥ", "ἦ", "ἧ":
                result.append("η")
            case "ί", "ὶ", "ῖ", "ἰ", "ἱ", "ἲ", "ἳ", "ἴ", "ἵ", "ἶ", "ἷ", "ϊ", "ΐ", "ῒ", "ῗ":
                result.append("ι")
            case "ό", "ὸ", "ὀ", "ὁ", "ὂ", "ὃ", "ὄ", "ὅ":
                result.append("ο")
            case "ύ", "ὺ", "ῦ", "ὐ", "ὑ", "ὒ", "ὓ", "ὔ", "ὕ", "ὖ", "ὗ", "ϋ", "ΰ", "ῢ", "ῗ":
                result.append("υ")
            case "ώ", "ὼ", "ῶ", "ὠ", "ὡ", "ὢ", "ὣ", "ὤ", "ὥ", "ὦ", "ὧ":
                result.append("ω")
            case "ς":
                result.append("σ")
            default:
                // Strip Latin diacritics via Unicode scalar folding if needed
                let s = String(char)
                let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                result.append(folded)
            }
        }
        
        return result
    }
    
    /// Transliterates Latin/English text into Greek characters.
    static func latinToGreek(_ text: String) -> String {
        var s = stripAccentsAndLowercase(text)
        
        // Handle soft C before e, i, y -> s, else k
        s = applySoftC(s)
        
        let digraphs: [(String, String)] = [
            ("ch", "χ"),
            ("kh", "χ"),
            ("th", "θ"),
            ("ph", "φ"),
            ("ps", "ψ"),
            ("ks", "ξ"),
            ("ck", "κ"),
            ("sh", "σ"),
            ("ts", "τσ"),
            ("tz", "τζ"),
            ("dz", "τζ"),
            ("ou", "ου"),
            ("ai", "αι"),
            ("ei", "ει"),
            ("oi", "οι"),
            ("mp", "μπ"),
            ("nt", "ντ"),
            ("gk", "γκ"),
            ("ng", "γγ"),
            ("gg", "γγ")
        ]
        
        for (lat, grk) in digraphs {
            s = s.replacingOccurrences(of: lat, with: grk)
        }
        
        let charMap: [Character: String] = [
            "a": "α", "b": "β", "d": "δ", "e": "ε", "f": "φ", "g": "γ",
            "h": "χ", "i": "ι", "j": "τζ", "k": "κ", "l": "λ", "m": "μ",
            "n": "ν", "o": "ο", "p": "π", "q": "κ", "r": "ρ", "s": "σ",
            "t": "τ", "u": "υ", "v": "β", "w": "ω", "x": "ξ", "y": "υ", "z": "ζ"
        ]
        
        var result = ""
        result.reserveCapacity(s.count)
        
        for c in s {
            if let mapped = charMap[c] {
                result.append(mapped)
            } else {
                result.append(c)
            }
        }
        
        return result
    }
    
    /// Transliterates Greek text into standard Latin characters.
    static func greekToLatin(_ text: String) -> String {
        var s = stripAccentsAndLowercase(text)
        
        s = applyGreekDiphthongs(s)
        
        let digraphs: [(String, String)] = [
            ("αι", "ai"),
            ("ει", "ei"),
            ("οι", "oi"),
            ("ου", "ou"),
            ("υι", "yi"),
            ("μπ", "b"),
            ("ντ", "d"),
            ("γκ", "g"),
            ("γγ", "ng"),
            ("τσ", "ts"),
            ("τζ", "tz")
        ]
        
        for (grk, lat) in digraphs {
            s = s.replacingOccurrences(of: grk, with: lat)
        }
        
        let charMap: [Character: String] = [
            "α": "a", "β": "v", "γ": "g", "δ": "d", "ε": "e", "ζ": "z",
            "η": "i", "θ": "th", "ι": "i", "κ": "k", "λ": "l", "μ": "m",
            "ν": "n", "ξ": "x", "ο": "o", "π": "p", "ρ": "r", "σ": "s",
            "ς": "s", "τ": "t", "υ": "y", "φ": "f", "χ": "ch", "ψ": "ps",
            "ω": "o"
        ]
        
        var result = ""
        result.reserveCapacity(s.count)
        
        for c in s {
            if let mapped = charMap[c] {
                result.append(mapped)
            } else {
                result.append(c)
            }
        }
        
        return result
    }
    
    /// Computes a canonical phonetic key collapsing sound-equivalent vowels, digraphs, and consonants.
    static func phoneticKey(_ text: String) -> String {
        var s = stripAccentsAndLowercase(text)
        s = applySoftC(s)
        s = applyGreekDiphthongs(s)
        
        // Greek diphthongs & consonant groups to canonical sounds
        let soundGroups: [(String, String)] = [
            ("αι", "e"),
            ("ει", "i"),
            ("οι", "i"),
            ("ου", "u"),
            ("υι", "i"),
            ("μπ", "b"),
            ("ντ", "d"),
            ("γκ", "g"),
            ("γγ", "ng"),
            ("τσ", "ts"),
            ("τζ", "tz"),
            
            // Latin digraphs & diphthongs to canonical sounds
            ("ch", "x"),
            ("kh", "x"),
            ("ph", "f"),
            ("th", "th"),
            ("ps", "ps"),
            ("ks", "ks"),
            ("ck", "k"),
            ("sh", "s"),
            ("ts", "ts"),
            ("tz", "tz"),
            ("dz", "tz"),
            ("ou", "u"),
            ("oo", "u"),
            ("ee", "i"),
            ("ea", "i"),
            ("ai", "e"),
            ("ei", "i"),
            ("qu", "k")
        ]
        
        for (pat, repl) in soundGroups {
            s = s.replacingOccurrences(of: pat, with: repl)
        }
        
        let greekPhoneticMap: [Character: String] = [
            "α": "a", "β": "v", "γ": "g", "δ": "d", "ε": "e", "ζ": "z",
            "η": "i", "θ": "th", "ι": "i", "κ": "k", "λ": "l", "μ": "m",
            "ν": "n", "ξ": "ks", "ο": "o", "π": "p", "ρ": "r", "σ": "s",
            "ς": "s", "τ": "t", "υ": "i", "φ": "f", "χ": "x", "ψ": "ps",
            "ω": "o"
        ]
        
        let latinPhoneticMap: [Character: String] = [
            "q": "k", "w": "o", "y": "i", "j": "tz", "b": "v", "x": "ks", "h": "x"
        ]
        
        var intermediate = ""
        intermediate.reserveCapacity(s.count)
        
        var index = s.startIndex
        while index < s.endIndex {
            // Check two-character "th"
            if s[index] == "t" {
                let next = s.index(after: index)
                if next < s.endIndex && s[next] == "h" {
                    intermediate.append("th")
                    index = s.index(after: next)
                    continue
                }
            }
            
            let c = s[index]
            if let mapped = greekPhoneticMap[c] {
                intermediate.append(mapped)
            } else if let mapped = latinPhoneticMap[c] {
                intermediate.append(mapped)
            } else {
                intermediate.append(c)
            }
            index = s.index(after: index)
        }
        
        // Collapse consecutive identical consonants/vowels except "th"
        return collapseDoubleLetters(intermediate)
    }
    
    // MARK: - Private Helpers
    
    private static func matchesToken(_ token: String, inCorpus corpus: [String]) -> Bool {
        let rawToken = stripAccentsAndLowercase(token)
        guard !rawToken.isEmpty else { return true }
        
        let greekToken = latinToGreek(rawToken)
        let latinToken = greekToLatin(rawToken)
        let phoneticToken = phoneticKey(rawToken)
        
        var queryCandidates = [rawToken]
        if !greekToken.isEmpty && greekToken != rawToken { queryCandidates.append(greekToken) }
        if !latinToken.isEmpty && latinToken != rawToken { queryCandidates.append(latinToken) }
        if !phoneticToken.isEmpty && phoneticToken != rawToken { queryCandidates.append(phoneticToken) }
        
        for corpusEntry in corpus {
            for q in queryCandidates {
                if corpusEntry.contains(q) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Soft C rule: `c` before `e`, `i`, or `y` is pronounced /s/ ("voice", "city"), otherwise /k/ ("cosmoradio", "club").
    private static func applySoftC(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        
        var index = text.startIndex
        while index < text.endIndex {
            let c = text[index]
            if c == "c" {
                let next = text.index(after: index)
                if next < text.endIndex {
                    let nextChar = text[next]
                    if nextChar == "e" || nextChar == "i" || nextChar == "y" {
                        result.append("s")
                    } else {
                        result.append("k")
                    }
                } else {
                    result.append("k")
                }
            } else {
                result.append(c)
            }
            index = text.index(after: index)
        }
        
        return result
    }
    
    /// Replaces Greek diphthongs `αυ` and `ευ` taking voiceless consonant environment into account:
    /// Before voiceless (θ, κ, ξ, π, σ, τ, φ, χ, ψ): af / ef
    /// Before voiced: av / ev
    private static func applyGreekDiphthongs(_ text: String) -> String {
        let voiceless: Set<Character> = ["θ", "κ", "ξ", "π", "σ", "τ", "φ", "χ", "ψ"]
        var result = ""
        result.reserveCapacity(text.count)
        
        var index = text.startIndex
        while index < text.endIndex {
            let c = text[index]
            let next = text.index(after: index)
            
            if (c == "α" || c == "ε" || c == "η") && next < text.endIndex && text[next] == "υ" {
                let following = text.index(after: next)
                let isVoiceless = following < text.endIndex && voiceless.contains(text[following])
                
                if c == "α" {
                    result.append(isVoiceless ? "af" : "av")
                } else if c == "ε" {
                    result.append(isVoiceless ? "ef" : "ev")
                } else {
                    result.append("iv")
                }
                index = following
                continue
            }
            
            result.append(c)
            index = next
        }
        
        return result
    }
    
    /// Collapses repeated identical characters (e.g. "ss" -> "s", "ll" -> "l"), preserving "th".
    private static func collapseDoubleLetters(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        
        var previous: Character?
        for c in text {
            if c == previous {
                continue
            }
            result.append(c)
            previous = c
        }
        
        return result
    }
}
