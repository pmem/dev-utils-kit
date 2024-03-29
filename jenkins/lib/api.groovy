// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2019-2021, Intel Corporation */

/* common functions and variables */

import java.util.regex.*

/* declarations of common paths and filenames: */

SCRIPTS_PATH = 'dev-utils-kit/jenkins/scripts'
OUTPUT_DIR_NAME = 'output'
RESULTS_DIR_NAME = 'results'

OUTPUT_DIR = "${WORKSPACE}/${OUTPUT_DIR_NAME}"
RESULTS_DIR = "${WORKSPACE}/${RESULTS_DIR_NAME}"
SCRIPTS_DIR = "${WORKSPACE}/${SCRIPTS_PATH}"

LOG_FILENAME = 'console.log'
LOG_FILE = "${OUTPUT_DIR}/${LOG_FILENAME}"

SYSTEM_INFO_FILENAME = 'system_info.txt'
SYSTEM_INFO_FILEPATH = "${RESULTS_DIR}/${SYSTEM_INFO_FILENAME}"

COMMON_FILE = "${SCRIPTS_DIR}/common.sh"

REVISION_FILENAME = "sha.txt"

/* A list of git revisions used in a job. It should contain a list of dicts (with 'url' and 'sha' keys). */
saved_git_revisions = []

/* Function for creating a log absolute filepath. */
def abs_logfile_path() {
	return "${WORKSPACE}/${OUTPUT_DIR_NAME}/${LOG_FILENAME}"
}

/* low-level functions for basic interaction with OS on the DUT: */

/* Requires the usage of top-level function inside a class method. */
TestsResult.metaClass.get_work_week_of_build_start = { get_work_week_of_build_start() }

/**
 * Runs a script in bash and logs its output.
 *
 * @param script_text Bash script's content. No need for shebang, pass only commands to execute.
 * @param log Path to the file where script's output will be redirected. If empty string, then no output redirection will be used. Default set to LOG_FILE.
 * @param import_common_file If set to true the 'common.sh' script will be included (default: false).
 * @param error_on_non_zero_rc If set to true function will raise error when command returns non-zero return code (default: true).
 * @return object with 'output' field, containing command's output, and 'status' with its returned code.
 */
def run_bash_script(script_text, log_file = LOG_FILE, import_common_file = false, error_on_non_zero_rc = true) {
	/**
	 * 1. Separates the log file for this current command exclusively, with a random name.
	 * 2. If requested - appends to the given log file.
	 */
	def current_script_output_file = "command_" + generate_random_string(20) + ".log"

	def redirect_script = """
		# ensure that this command output file is empty:
		echo "" > ${current_script_output_file}
		# ensure that log_file exists before using `tee -a`:
		touch ${log_file} ${current_script_output_file}
		# redirect stdout to the named pipe:
		exec > >(tee -a ${log_file} ${current_script_output_file})
		# merge stderr stream with stdout:
		exec 2>&1
	"""

	/* Imports things defined in common.sh file if not set otherwise. */
	def source_script = (import_common_file == false) ? "" : "source ${COMMON_FILE}"

	def full_script_body =  """#!/usr/bin/env bash
		set -o pipefail
		${redirect_script}
		${source_script}
		# now do whatever user wanted to:
		${script_text}
	"""

	/* Does the actual call. */
	def returned_status = sh(script: full_script_body, returnStatus: true)

	/* Captures the script output from the file. */
	def script_output = readFile current_script_output_file

	/* Deletes the log file. */
	sh "rm -f ${current_script_output_file}"

	/* Capturing status is also disabling default behavior of `sh` - error when exit status != 0. */
	/* Here restore that behavior if not requested otherwise. */
	if (error_on_non_zero_rc && returned_status != 0) {
		error("script returned exit code ${returned_status}")
	}
	
	def retval = [:]
	retval.output = script_output.trim()
	retval.status = returned_status
	return retval
}

/**
 * Runs a script in bash and logs its output. Includes sourced 'common.sh'.
 * @param script_text Bash script's content. No need for shebang, pass only commands to execute.
 * @param log Path to the file where script's output will be redirected. If empty string, then no output redirection will be used. Default set to LOG_FILE.
 * @param error_on_non_zero_rc If set to true it will raise error when command returns non-zero return code (Default: true).
 * @return object with 'output' field, containing command's output, and 'status' with its returned code.
 */
def run_bash_script_with_common(script_text, log = LOG_FILE, error_on_non_zero_rc = true) {
	return run_bash_script(script_text, log, true, error_on_non_zero_rc)
}

/**
 * Runs CMake script, with parameters and extra env vars, if needed.
 * @param path A path pointing to the directory with CMakeLists.txt file.
 * @param parameters Additional parameters for CMake configuration.
 * @param additional_env_vars Set additional env vars.
 */
def run_cmake(path, parameters = "", additional_env_vars = "") {
	if (additional_env_vars != "") {
		additional_env_vars = "export ${additional_env_vars} &&"
	}

	run_bash_script("${additional_env_vars} cmake ${path} ${parameters}")
}

/**
 * Runs 'make' (on all available cores), with parameters and extra env vars, if needed.
 * @param parameters Additional parameters for make configuration.
 * @param additional_env_vars Set additional env vars.
 */
def run_make(parameters = "", additional_env_vars = "") {
	if (additional_env_vars != "") {
		additional_env_vars = "export ${additional_env_vars} &&"
	}

	run_bash_script("${additional_env_vars} make -j\$(nproc) ${parameters}")
}

/**
 * Prints provided text to the output log.
 * Used for logs that are intended to be stored additionally on the tested server e.g. for later use or archiving purposes.
 * @param text String to print in bash.
 */
def run_echo(text) {
	run_bash_script("echo \"${text}\"")
}

/**
 * Adds repository revision to saved revisions. This is used for example to send an e-mail with the test result.
 * If the requested repository (matching URL and SHA) is already known, it is not added for the second time.
 * However - if, for example, provided repo was added previously with a different SHA, it will be added as a separate entry.
 * @param repo_url URL of a repository.
 * @param repo_sha SHA of a repository revision.
 */
def save_git_revision(repo_url, repo_sha) {
	def current_repo_revision = [:]

	current_repo_revision.url = repo_url
	current_repo_revision.sha = repo_sha

	if(!this.saved_git_revisions.contains(current_repo_revision)) {
		this.saved_git_revisions.add(current_repo_revision)
	}
}

/**
 * Returns git revision string with all cloned repositories.
 * @return All cloned repos revisions in the form of one string.
 */
def get_revision_version() {
	def revision_string = ""

	this.saved_git_revisions.each {
		revision_string += it.url + ":\n" + it.sha + "\n"
	}

	return revision_string
}

/**
 * Prints given text as the header in Jenkins log and bash's output.
 * @param text String to print in header.
 */
def echo_header(text) {
	def header = "*********************************** ${text} ***********************************"

	/* echo to Jenkins log: */
	echo header

	/* echo to console output: */
	run_echo(header)
}

/**
 * Generates random alphanumeric string.
 * @param length Number of characters to generate.
 */
def generate_random_string(length) {
	String chars = (('a'..'z') + ('A'..'Z') + ('0'..'9')).join('')
	Random rnd = new Random()
	def random_string = ""

	for(i = 0; i < length; i++) {
		random_string = random_string + chars.charAt(rnd.nextInt(chars.length()))
	}

	return random_string
}

/* higher-level functions for dealing with parts of pipelines' stages */

/**
 * Downloads repository with git.
 * @param repo_url URL to requested repository.
 * @param branch Specified branch to checkout.
 * @param target_directory Directory to which repository will be cloned. If not specified, it will be cloned into the current working directory.
 * @param keep_sha If false, it disables storing the cloned repo SHA in the list.
 */
def clone_repository(repo_url, branch, target_directory = '', keep_sha = true) {
	def specified_target_dir = (target_directory == '') ? false : true

	/* If target dir is not specified, then we will create temporary dir and then copy contents to current dir. */
	/* The reason is: checkout will remove all files from the current dir if it's not empty. */
	if(!specified_target_dir) {
		target_directory = "repository_target_temp_${generate_random_string(8)}"
	}

	def revision = checkout([$class: 'GitSCM', branches: [[name: "${branch}"]], doGenerateSubmoduleConfigurations: false,
		extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: target_directory]], submoduleCfg: [],
		userRemoteConfigs: [[url: repo_url]]])

	this.echo_header("Git log")
	if (keep_sha) {
		this.save_git_revision(repo_url, revision.GIT_COMMIT)
	}

	dir(target_directory) {
		run_bash_script("git log --oneline -n 5")
	}

	dir(OUTPUT_DIR_NAME) {
		writeFile file: REVISION_FILENAME, text: this.get_revision_version()
	}

	if(!specified_target_dir) {
		run_bash_script("""
			# move all files (including hidden ones) from target_directory:
			mv -f ${target_directory}/{.[!.],}* ./

			# delete target directory:
			rmdir ${target_directory}
		""")
	}
}

/**
 * Sets a moose as a welcome message after logging to the DUT, which will warn about running execution.
 */
def set_jenkins_warning_on_dut() {
	run_bash_script_with_common("set_warning_message ${info_addr}")
}

/**
 * Restores default welcome message after logging to the DUT which means that Jenkins' execution is done.
 */
def unset_jenkins_warning_on_dut() {
	run_bash_script_with_common("disable_warning_message")
}

/**
 * Prints OS and BRANCH params of the current job to Jenkins. Call script which collects system info and saves it to logs.
 */
def system_info() {
	echo_header("system info")

	dir(RESULTS_DIR_NAME) {
		writeFile file: SYSTEM_INFO_FILENAME, text: ''
	}

	print "OS: ${params.LABEL}"
	print "Branch: ${params.BRANCH}"

	run_bash_script_with_common("""
		system_info 2>&1 | tee -a ${SYSTEM_INFO_FILEPATH}
	""")
}

/**
 * Enumeration of distributions.
 */
enum DistroName {

	UNKNOWN(''),
	DEBIAN('Debian GNU/Linux'),
	CENTOS('CentOS Linux'),
	OPENSUSE('openSUSE Leap'),
	FEDORA('Fedora'),
	UBUNTU('Ubuntu'),
	RHEL('Red Hat Enterprise Linux'),
	RHELS('Red Hat Enterprise Linux Server')

	/**
	 * Constructor for assigning proper values to enumerators' properties.
	 * @param name Name of the distribution.
	 */
	DistroName(String distro_name) {
		this.distro_name = distro_name
	}

	def to_string() {
		return this.distro_name
	}

	static def from_string(string_distro_name) {
		/* lookup in all enum labels and check if the  given string matches */
		for (DistroName distro_name : DistroName.values()) {
			if (distro_name.to_string() == string_distro_name) {
				return distro_name
			}
		}

		return DistroName.UNKNOWN
	}

	private final String distro_name
}

/* This is necessary in order to closure work properly with enum after loading the file in the pipeline. */
this.DistroName = DistroName

/**
 * Archives the artifacts from the output directory.
 */
def archive_output() {
	archiveArtifacts artifacts: "${OUTPUT_DIR_NAME}/*.*"
}

/**
 * Archives the artifacts from output and results directory.
 */
def archive_results_and_output() {
	archive_output()
	archiveArtifacts artifacts: "${RESULTS_DIR_NAME}/*.*"
}

/**
 * Writes 'result' file (success, fail) and archives it.
 * @param result String representing result (could be e.g. 'success' or 'fail').
 */
def write_result_and_archive(result) {
	dir(RESULTS_DIR_NAME) {
		writeFile file: "${result}.txt", text: result
	}

	archiveArtifacts artifacts: "${RESULTS_DIR_NAME}/*.*"
}

/**
 * Writes a file with the name OS_BRANCH_REPO.txt to results dir.
 */
def write_os_branch_repo(os, branch = null, repo = null) {
	def branch_chunk = (branch == null) ? "" : "_${branch}"
	def repo_chunk = (repo == null) ? "" : "_${repo}"
	def filename = "${os}${branch_chunk}${repo_chunk}.txt"

	dir(RESULTS_DIR_NAME) {
		writeFile file: filename, text: ''
	}
}

/**
 * Gets the week number of date when current build has started.
 * Assume that the start of the week is on Monday.
 */
def get_work_week_of_build_start() {
	/**
	 * Groovy sandbox does not allow to change properties of locale, default start of the week is on Sunday,
	 * so we need to make a trick: shift the starting date by one day ahead - this will give us the result proper week
	 * number with starting on Monday.
	 *
	 * Groovy sandbox does not allow the creation of Date objects with constructor different than Unix milliseconds epoch,
	 * so we cannot count in days but only in milliseconds.
	 * (24 hours / 1 day) * (60 minutes / 1 hour) * (60 seconds / 1 minute) * (1000 milliseconds / 1 second)
	 */
	def one_day_in_ms = 24 * 60 * 60 * 1000

	/*  Gets build start date object. */
	def start_date = new Date(currentBuild.startTimeInMillis + one_day_in_ms)

	/*  Gets week number and casts it to integer. */
	return Integer.valueOf(start_date.format("w"))
}

class TestsResult {
	Integer all = 0
	Integer passed = 0
	Integer failed = 0
	Integer skipped = 0
	def currentBuild, env

	TestsResult (results = [], def currentBuild, def env) {
		results.each {
			if (it != null) {
				this.all += it.getTotalCount()
				this.passed += it.getPassCount()
				this.failed += it.getFailCount()
				this.skipped += it.getSkipCount()
			}
		}

		this.currentBuild = currentBuild
		this.env = env
	}

	def get_html_table_data_row() {
		def build_name_id = "${currentBuild.projectName}/${currentBuild.id}"
		def urls =
				"""<a href="${env.JENKINS_URL}/blue/organizations/jenkins/${currentBuild.projectName}/detail/${build_name_id}/pipeline\">blue</a>,
				 <a href="${env.JENKINS_URL}/blue/organizations/jenkins/${currentBuild.projectName}/detail/${build_name_id}/tests\">blue tests</a>,
				 <a href="${env.JENKINS_URL}/view/all/job/${build_name_id}/testReport\">tests</a>,
				 <a href="${env.JENKINS_URL}/view/all/job/${build_name_id}/\">build</a>,
				 <a href="${env.JENKINS_URL}/view/all/job/${build_name_id}/consoleText\">console</a>,
				 <a href="${env.JENKINS_URL}/job/${build_name_id}/artifact/results/system_info.txt\">system_info</a>"""

		return """
				<tr>
					<td>${currentBuild.projectName}</td>
					<td>${currentBuild.displayName}</td>
					<td>ww${get_work_week_of_build_start()} ${new Date(currentBuild.startTimeInMillis).format("dd.MM.yyyy HH:mm")}</td>
					<td>${currentBuild.durationString}</td>
					<td>${currentBuild.currentResult}</td>
					<td>${urls}</td>
					<td>${this.all}</td>
					<td>${this.passed}</td>
					<td>${this.skipped}</td>
					<td>${this.failed}</td>
				</tr>
		"""
	}

	def get_html_table_heading_row() {
		return """
			<tr>
				<th>Pipeline</th>
				<th>Build</th>
				<th>Starting time</th>
				<th>Duration</th>
				<th>Pipeline status</th>
				<th>URLs</th>
				<th>All tests</th>
				<th>Passed</th>
				<th>Skipped</th>
				<th>Failed</th>
			</tr>
		"""
	}

	def get_html_table() {
		return """
			<table border="1">
				${this.get_html_table_heading_row()}
				${this.get_html_table_data_row()}
			</table>
		"""
	}
}

/**
 * Sends summary with test results via email.
 * @param results List of objects returned by `junit` call.
 * @param recipients Addressee of the mail.
 */
def send_test_summary_via_mail(results = [], recipients = params.EMAIL_RECIPIENTS) {
	def message_title = "[Jenkins] Report ${currentBuild.projectName} ${currentBuild.displayName}, ww ${get_work_week_of_build_start()}"
	def tests_results = new TestsResult(results, currentBuild, env)
	def message_body =	"""
		${tests_results.get_html_table()}
		<p>---<br />generated automatically by <a href="${env.JENKINS_URL}">Jenkins</a></p>
	"""

	mail (
		to: recipients,
		subject: message_title,
		body: message_body,
		mimeType: "text/html"
	)
}

def check_os() {
	distro = sh(script:
	"""#!/usr/bin/env bash
		source ${libs.api.COMMON_FILE}
		check_distro
	""", returnStdout: true).trim()

	return DistroName.from_string(distro)
}

/**
 * Applies regular expression to a text.
 * @param text Text to apply regex to - input for a regex engine.
 * @param pattern Regex pattern to be searched by a regex engine.
 * @param groups List of expected group names to be extracted.
 * @param pattern_flags Flags for regex engine. Default: MULTILINE | COMMENTS
 * @return list of dictionaries with all matched groups.
 * Example:
 * def input_string = "changed: 10.91.28.117\nok: 0.91.28.119"
 * def pattern = $/ ^(?<status>\w+):\s(?<ip>[\w.]+)$ /$
 * def groups = ["status", "ip"]
 * def result = apply_regex(input_string, pattern, groups)
 * // result will contain list of matches: [[status:changed, ip:10.91.28.117], [status:ok, ip:0.91.28.119]]
 */
@NonCPS
def apply_regex(text, pattern, groups, pattern_flags = Pattern.COMMENTS | Pattern.MULTILINE) {
	Matcher regex_matcher = Pattern.compile(pattern, pattern_flags).matcher(text);
	def found_matches = []

	while (regex_matcher.find()) {
		def current_match = [:]
		for (current_group in groups) {
			current_match[current_group] = regex_matcher.group(current_group)
		}
		found_matches.add(current_match)
	}

	return found_matches
}

/* below is necessary in order to closure work properly after loading the file in the pipeline: */
return this
