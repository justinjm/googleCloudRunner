#' Create a yaml build step
#'
#' Helper for creating build steps for upload to Cloud Build
#'
#' @param name name of docker image to call appended to \code{prefix}
#' @param args character vector of arguments
#' @param prefix prefixed to name - set to "" to suppress.  Will be suppressed if \code{name} starts with gcr.io
#' @param entrypoint change the entrypoint for the docker container
#' @param dir The directory to use, relative to /workspace e.g. /workspace/deploy/
#' @param id Optional id for the step
#' @param env Environment variables for this step.  A character vector for each assignment
#' @param volumes volumes to connect and write to
#'
#' @seealso \href{https://cloud.google.com/cloud-build/docs/create-custom-build-steps}{Creating custom build steps how-to guide}
#'
#' @details
#' By default dir is set to \code{deploy} to aid deployment from GCS, but you may want to set this to \code{""} when using \link{RepoSource}
#'
#'
#' @section Build Macros:
#' Fields can include the following variables, which will be expanded when the build is created:-
#'
#' \itemize{
#'   \item $PROJECT_ID: the project ID of the build.
#'   \item $BUILD_ID: the autogenerated ID of the build.
#'   \item $REPO_NAME: the source repository name specified by RepoSource.
#'   \item $BRANCH_NAME: the branch name specified by RepoSource.
#'   \item $TAG_NAME: the tag name specified by RepoSource.
#'   \item $REVISION_ID or $COMMIT_SHA: the commit SHA specified by RepoSource or  resolved from the specified branch or tag.
#'   \item  $SHORT_SHA: first 7 characters of $REVISION_ID or $COMMIT_SHA.
#' }
#'
#' Or you can add your own custom variables, set in the Build Trigger.  Custom variables always start with $_ e.g. $_MY_VAR
#'
#' @export
#' @family Cloud Buildsteps
#' @examples
#'
#' # creating yaml for use in deploying cloud run
#' image = "gcr.io/my-project/my-image:$BUILD_ID"
#' cr_build_yaml(
#'     steps = c(
#'          cr_buildstep("docker", c("build","-t",image,".")),
#'          cr_buildstep("docker", c("push",image)),
#'          cr_buildstep("gcloud", c("beta","run","deploy", "test1",
#'                                    "--image", image))),
#'     images = image)
#'
#' # use premade docker buildstep - combine using c()
#' image = "gcr.io/my-project/my-image"
#' cr_build_yaml(
#'     steps = c(cr_buildstep_docker(image),
#'               cr_buildstep("gcloud",
#'                      args = c("beta","run","deploy",
#'                               "test1","--image", image))
#'              ),
#'     images = image)
#'
#' # list files with a new entrypoint for gcloud
#' cr_build_yaml(steps = cr_buildstep("gcloud", c("-c","ls -la"),
#'                                    entrypoint = "bash"))
#'
#' # to call from images not using gcr.io/cloud-builders stem
#' cr_buildstep("alpine", c("-c","ls -la"), entrypoint = "bash", prefix="")
#'
#' # to add environment arguments to the step
#' cr_buildstep("docker", "version", env = c("ENV1=env1", "ENV2=$PROJECT_ID"))
#'
#' # to add volumes wrap in list()
#' cr_buildstep("test", "ls", volumes = list(list(name = "ssh", path = "/root/.ssh")))
#'
cr_buildstep <- function(name,
                         args,
                         id = NULL,
                         prefix = "gcr.io/cloud-builders/",
                         entrypoint = NULL,
                         dir = "",
                         env = NULL,
                         volumes = NULL){

  if(is.null(prefix) || is.na(prefix)){
    prefix <- "gcr.io/cloud-builders/"
  }

  if(dir %in% c("",NA)) dir <- NULL

  if(grepl("^gcr.io", name)){
    prefix <- ""
  }

  list(structure(
    rmNullObs(list(
      name = paste0(prefix, name),
      entrypoint = entrypoint,
      args = args,
      id = id,
      dir = dir,
      env = env,
      volumes = volumes
    )), class = c("cr_buildstep","list")))
}

is.cr_buildstep <- function(x){
  inherits(x, "cr_buildstep")
}

#' Convert a data.frame into cr_buildstep
#'
#' Helper to turn a data.frame of buildsteps info into format accepted by \link{cr_build}
#'
#' @param x A data.frame of steps to turn into buildsteps, with at least name and args columns
#'
#' @details
#' This helps convert the output of \link{cr_build} into valid \link{cr_buildstep} so it can be sent back into the API
#'
#' If constructing arg list columns then \link{I} suppresses conversion of the list to columns that would otherwise break the yaml format
#' @export
#' @family Cloud Buildsteps
#' @examples

#' y <- data.frame(name = c("docker", "alpine"),
#'                 args = I(list(c("version"), c("echo", "Hello Cloud Build"))),
#'                 id = c("Docker Version", "Hello Cloud Build"),
#'                 prefix = c(NA, ""),
#'                 stringsAsFactors = FALSE)
#' cr_buildstep_df(y)
cr_buildstep_df <- function(x){
  assert_that(
    is.data.frame(x),
    all(c('name', 'args') %in% names(x))
  )

  if(is.null(x$prefix)){
    #probably from API
    x$prefix <- ""
  }

  if(is.null(x$dir)){
    x$dir <- ""
  }

  xx <- x[, intersect(c("name",
                        "args",
                        "id",
                        "prefix",
                        "entrypoint",
                        "dir",
                        "env",
                        "volumes"), names(x))]

  apply(xx, 1, function(row){
    cr_buildstep(name = row[["name"]],
                 args = row[["args"]],
                 id = row[["id"]],
                 prefix = row[["prefix"]],
                 entrypoint = row[["entrypoint"]],
                 env = row[["env"]],
                 volumes = row[["volumes"]],
                 dir = row[["dir"]])[[1]]
  })

}


#' Extract a buildstep from a Build object
#'
#' Useful if you have a step from an existing cloudbuild.yaml you want in another
#'
#' @param x A \link{Build} object
#' @param step The numeric step number to extract
#' @family Cloud Buildsteps
#' @export
#' @examples
#' package_build <- system.file("cloudbuild/cloudbuild.yaml",
#'                              package = "googleCloudRunner")
#' build <- cr_build_make(package_build)
#' build
#' cr_buildstep_extract(build, step = 1)
#' cr_buildstep_extract(build, step = 2)
cr_buildstep_extract <- function(x, step = NULL){

  assert_that(is.gar_Build(x))

  the_step <- x$steps[[step]]
  the_step$prefix <- ""

  do.call(cr_buildstep,
          args = the_step)

}

#' Modify an existing buildstep with new parameters
#'
#' Useful for editing existing buildsteps
#'
#' @inheritDotParams cr_buildstep
#' @param x A buildstep created previously
#' @export
#' @family Cloud Buildsteps
#' @examples
#' package_build <- system.file("cloudbuild/cloudbuild.yaml",
#'                              package = "googleCloudRunner")
#' build <- cr_build_make(package_build)
#' build
#' cr_buildstep_extract(build, step = 1)
#' cr_buildstep_extract(build, step = 2)
#'
#' edit_me <- cr_buildstep_extract(build, step = 2)
#' cr_buildstep_edit(edit_me, name = "blah")
#' cr_buildstep_edit(edit_me, name = "gcr.io/blah")
#' cr_buildstep_edit(edit_me, args = c("blah1","blah2"), dir = "meh")
cr_buildstep_edit <- function(x,
                              ...){
  #buildsteps are in a list()
  xx  <- x[[1]]

  assert_that(is.cr_buildstep(xx))

  dots <- list(...)

  # make sure required params are there
  the_name <- dots$name
  if(is.null(the_name)){
    the_name <- xx$name
  }

  the_args <- dots$args
  if(is.null(the_args)){
    the_args <- xx$args
  }

  dots$name <- the_name
  dots$args <- the_args

  do.call(cr_buildstep, args = dots)

}
