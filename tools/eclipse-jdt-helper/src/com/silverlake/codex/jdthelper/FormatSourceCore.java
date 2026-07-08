package com.silverlake.codex.jdthelper;

import org.eclipse.jdt.core.ToolFactory;
import org.eclipse.jdt.core.formatter.CodeFormatter;
import org.eclipse.jface.text.Document;
import org.eclipse.osgi.util.NLS;
import org.eclipse.text.edits.TextEdit;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

final class FormatSourceCore {

	private static final String ARG_PROFILE_PATH = "--profile-path";
	private static final String PROFILE_ELEMENT = "profile";
	private static final String SETTING_ELEMENT = "setting";
	private static final String PROFILE_NAME_ATTRIBUTE = "name";
	private static final String SETTING_ID_ATTRIBUTE = "id";
	private static final String SETTING_VALUE_ATTRIBUTE = "value";

	private FormatSourceCore() {
	}

	static void runFormatting(String[] args) throws Exception {
		Arguments parsed = Arguments.parse(args);
		Map<String, String> formatterOptions = loadFormatterOptions(parsed.profilePath);

		for (Path filePath : parsed.filePaths) {
			formatFile(filePath, formatterOptions);
		}
	}

	private static Map<String, String> loadFormatterOptions(Path profilePath) throws Exception {
		org.w3c.dom.Document xmlDocument = DocumentBuilderFactory.newInstance().newDocumentBuilder()
				.parse(profilePath.toFile());
		NodeList profileNodes = xmlDocument.getElementsByTagName(PROFILE_ELEMENT);
		if (profileNodes.getLength() == 0) {
			throw new IllegalArgumentException("No formatter profile found in " + profilePath);
		}

		Element profileElement = (Element) profileNodes.item(0);
		NodeList settingNodes = profileElement.getElementsByTagName(SETTING_ELEMENT);
		Map<String, String> formatterOptions = new LinkedHashMap<>();
		for (int index = 0; index < settingNodes.getLength(); index++) {
			Element settingElement = (Element) settingNodes.item(index);
			String key = settingElement.getAttribute(SETTING_ID_ATTRIBUTE);
			String value = settingElement.getAttribute(SETTING_VALUE_ATTRIBUTE);
			if (!key.isBlank() && !value.isBlank()) {
				formatterOptions.put(key, value);
			}
		}

		if (formatterOptions.isEmpty()) {
			String profileName = profileElement.getAttribute(PROFILE_NAME_ATTRIBUTE);
			throw new IllegalArgumentException("No formatter settings found in profile "
					+ (profileName.isBlank() ? "<unnamed>" : profileName) + " from " + profilePath);
		}

		return formatterOptions;
	}

	private static void formatFile(Path filePath, Map<String, String> formatterOptions) throws Exception {
		String source = Files.readString(filePath, StandardCharsets.UTF_8);
		String lineSeparator = detectLineSeparator(source);
		CodeFormatter formatter = ToolFactory.createCodeFormatter(formatterOptions);
		TextEdit edit = formatter.format(CodeFormatter.K_COMPILATION_UNIT | CodeFormatter.F_INCLUDE_COMMENTS, source, 0,
				source.length(), 0, lineSeparator);

		if (edit == null) {
			throw new IllegalStateException("Formatter returned no edits for " + filePath);
		}

		Document document = new Document(source);
		edit.apply(document);
		String formattedSource = document.get();
		if (!source.equals(formattedSource)) {
			Files.writeString(filePath, formattedSource, StandardCharsets.UTF_8);
		}
	}

	private static String detectLineSeparator(String source) {
		if (source.contains("\r\n")) {
			return "\r\n";
		}
		if (source.contains("\n")) {
			return "\n";
		}
		return System.lineSeparator();
	}

	private record Arguments(Path profilePath, List<Path> filePaths) {

		private static Arguments parse(String[] args) {
			Map<String, String> namedArguments = new LinkedHashMap<>();
			List<Path> filePaths = new ArrayList<>();

			for (int index = 0; index < args.length; index++) {
				String argument = args[index];
				if (ARG_PROFILE_PATH.equals(argument)) {
					if (index + 1 >= args.length) {
						throw new IllegalArgumentException("Missing value for " + argument);
					}
					namedArguments.put(argument, args[++index]);
					continue;
				}
				filePaths.add(normalizePath(argument));
			}

			String profilePath = namedArguments.get(ARG_PROFILE_PATH);
			if (profilePath == null || profilePath.isBlank()) {
				throw new IllegalArgumentException(ARG_PROFILE_PATH + " is required.");
			}
			if (filePaths.isEmpty()) {
				throw new IllegalArgumentException("No Java files were provided to format.");
			}

			return new Arguments(normalizePath(profilePath), filePaths);
		}

		private static Path normalizePath(String rawPath) {
			try {
				return Paths.get(rawPath).toAbsolutePath().normalize();
			} catch (InvalidPathException exception) {
				throw new IllegalArgumentException(NLS.bind("Invalid path: {0}", rawPath), exception);
			}
		}
	}
}
