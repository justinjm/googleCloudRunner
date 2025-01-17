% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cloudbuild.R
\name{cr_build}
\alias{cr_build}
\title{Starts a build with the specified configuration.}
\usage{
cr_build(x, source = NULL, timeout = NULL, images = NULL,
  projectId = cr_project_get(), launch_browser = interactive())
}
\arguments{
\item{x}{A cloudbuild.yaml file location or an R object that will be turned into yaml via \link[yaml]{as.yaml} or a \link{Build} object created by \link{cr_build_make} or from a previous build you want to rerun.}

\item{source}{A \link{Source} object specifying the location of the source files to build, usually created by \link{cr_build_source}}

\item{timeout}{Amount of time that this build should be allowed to run, to second}

\item{images}{A list of images to be pushed upon the successful completion of all build}

\item{projectId}{ID of the project}

\item{launch_browser}{Whether to launch the logs URL in a browser once deployed}
}
\description{
This method returns a long-running `Operation`, which includes the buildID. Pass the build ID to \link{cr_build_status} to determine the build status (such as `SUCCESS` or `FAILURE`).
}
\examples{

my_gcs_source <- Source(storageSource=StorageSource("gs://my-bucket", "my_code.tar.gz"))
my_gcs_source

my_repo_source <- Source(repoSource=RepoSource("https://my-repo.com", branchName="master"))
my_repo_source
\dontrun{

# build from a cloudbuild.yaml file
cloudbuild_file <- system.file("cloudbuild/cloudbuild.yaml",
                               package="googleCloudRunner")

# asynchronous, will launch log browser by default
b1 <- cr_build(cloudbuild_file)

# synchronous waiting for build to finish
b2 <- cr_build_wait(b1)

# the same results
cr_build_status(b1)
cr_build_status(b2)

# build from a cloud storage source
build1 <- cr_build(cloudbuild_file,
                   source = my_gcs_source)
# build from a git repository source
build2 <- cr_build(cloudbuild_file,
                   source = my_repo_source)

# you can send in results for previous builds to trigger
# the same build under a new Id
# will trigger build2 again
cr_build(build2)


}
}
\seealso{
\href{https://cloud.google.com/cloud-build/docs/}{Google Documentation for Cloud Build}

Other Cloud Build functions: \code{\link{Build}},
  \code{\link{RepoSource}}, \code{\link{Source}},
  \code{\link{StorageSource}}, \code{\link{cr_build_make}},
  \code{\link{cr_build_status}},
  \code{\link{cr_build_upload_gcs}},
  \code{\link{cr_build_wait}},
  \code{\link{cr_build_write}}, \code{\link{cr_build_yaml}}
}
\concept{Cloud Build functions}
