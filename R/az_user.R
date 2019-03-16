#' User in Azure Active Directory
#'
#' Base class representing an AAD user account.
#'
#' @docType class
#' @section Methods:
#' - `new(...)`: Initialize a new user object. Do not call this directly; see 'Initialization' below.
#' - `delete(confirm=TRUE)`: Delete a user account. By default, ask for confirmation first.
#' - `update(...)`: Update the user information in Azure Active Directory.
#' - `sync_fields()`: Synchronise the R object with the app data in Azure Active Directory.
#' - `reset_password(password=NULL, force_password_change=TRUE): Resets a user password. By default the new password will be randomly generated, and must be changed at next login.
#'
#' @section Initialization:
#' Creating new objects of this class should be done via the `create_user` and `get_user` methods of the [az_graph] and [az_app] classes. Calling the `new()` method for this class only constructs the R object; it does not call the AD Graph API to create the actual user account.
#'
#' @seealso
#' [az_graph], [az_app], [az_group]
#'
#' [Azure AD Graph overview](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-graph-api),
#' [REST API reference](https://docs.microsoft.com/en-au/previous-versions/azure/ad/graph/api/api-catalog)
#'
#' @format An R6 object of class `az_user`.
#' @export
az_user <- R6::R6Class("az_user",

public=list(

    token=NULL,
    tenant=NULL,

    # app data from server
    properties=NULL,

    initialize=function(token, tenant=NULL, properties=NULL, password=NULL)
    {
        self$token <- token
        self$tenant <- tenant
        self$properties <- properties
        private$password <- password
    },

    reset_password=function(password=NULL, force_password_change=TRUE)
    {
        if(is.null(password))
        {
            chars <- c(letters, LETTERS, 0:9, "~", "!", "@", "#", "$", "%", "&", "*", "(", ")", "-", "+")
            password <- paste0(sample(chars, 50, replace=TRUE), collapse="")
        }

        properties <- list(
            passwordProfile=list(
                password=password,
                forceChangeAtNextLogin=force_password_change
            )
        )

        op <- file.path("users", self$properties$objectId)
        private$graph_op(op, body=properties, encode="json", http_verb="PATCH")
        private$graph_op(op)
        private$password <- password
        password
    },

    update=function(...)
    {
        op <- file.path("users", self$properties$objectId)
        private$graph_op(op, body=list(...), encode="json", http_verb="PATCH")
        self$properties <- private$graph_op(op)
        self
    },

    sync_fields=function()
    {
        op <- file.path("users", self$properties$objectId)
        self$properties <- private$graph_op(op)
        invisible(self)
    },

    delete=function(confirm=TRUE)
    {
        if(confirm && interactive())
        {
            msg <- paste0("Do you really want to delete the user '", self$properties$displayName,
                          "'? (y/N) ")
            yn <- readline(msg)
            if(tolower(substr(yn, 1, 1)) != "y")
                return(invisible(NULL))
        }

        op <- file.path("users", self$properties$objectId)
        private$graph_op(op, http_verb="DELETE")
        invisible(NULL)
    }
),

private=list(

    password=NULL,

    graph_op=function(op="", ...)
    {
        call_graph_endpoint(self$token, self$tenant, op, ...)
    }
))