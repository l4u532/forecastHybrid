#' Test if the object is a hybridModel object
#'
#' Test if the object is a \code{hybridModel} object.
#'
#' @export
#' @param x the input object.
#' @return A boolean indicating if the object is a \code{hybridModel} is returned.
#'
is.hybridModel <- function(x){
  inherits(x, "hybridModel")
}

#' Extract Model Fitted Values
#'
#' Extract the model fitted values from the \code{hybridModel} object.
#'
#' @param object the input hybridModel.
#' @param individual if \code{TRUE}, return the fitted values of the component models instead
#' of the fitted values for the whole ensemble model.
#' @param ... other arguments (ignored).
#' @seealso \code{\link{accuracy}}
#' @return The fitted values of the ensemble or individual component models.
#' @export
#'
fitted.hybridModel <- function(object,
                               individual = FALSE,
                               ...){
  #chkDots(...)
  if(individual){
    results <- list()
    for(i in object$models){
      results[[i]] <- fitted(object[[i]])
    }
    return(results)
  }
  return(object$fitted)
}

#' Extract Model Residuals
#'
#' Extract the model residuals from the \code{hybridModel} object.
#' @export
#' @param object The input hybridModel.
#' @param individual If \code{TRUE}, return the residuals of the component models instead
#' of the residuals for the whole ensemble model.
#' @param ... Other arguments (ignored).
#' @seealso \code{\link{accuracy}}
#' @return The residuals of the ensemble or individual component models.
#'
residuals.hybridModel <- function(object,
                                  individual = FALSE,
                                  ...){
  #chkDots(...)
  if(individual){
    results <- list()
    for(i in object$models){
      results[[i]] <- residuals(object[[i]])
    }
    return(results)
  }
  return(object$residuals)
}


#' Accuracy measures for hybridModel objects
#'
#' Accuracy measures for hybridModel
#' objects.
#'
#' Return the in-sample accuracy measures for the component models of the hybridModel
#'
#' @param f the input hybridModel.
#' @param individual if \code{TRUE}, return the accuracy of the component models instead
#' of the accuracy for the whole ensemble model.
#' @param ... other arguments (ignored).
#' @seealso \code{\link[forecast]{accuracy}}
#' @return The accuracy of the ensemble or individual component models.
#' @export
#'
#' @author David Shaub
#'
accuracy.hybridModel <- function(f,
                                 individual = FALSE,
                                 ...){
  #chkDots(...)
  if(individual){
    results <- list()
    for(i in f$models){
      results[[i]] <- forecast::accuracy(f[[i]])
    }
    return(results)
  }
  return(forecast::accuracy(f$fitted, getResponse(f)))
}

#' Accuracy measures for cross-validated time series
#'
#' Returns range of summary measures of the cross-validated forecast accuracy
#' for \code{cvts} objects.
#'
#' @param f a \code{cvts} objected created by \code{\link{cvts}}.
#' @param ... other arguments (ignored).
#'
#' @details
#' Currently the method only implements \code{ME}, \code{RMSE}, and \code{MAE}. The accuracy measures
#' \code{MPE}, \code{MAPE}, and \code{MASE} are not calculated. The accuracy is calculated for each
#' forecast horizon up to \code{maxHorizon}
#' @export
#' @author David Shaub
#' 
accuracy.cvts <- function(f, ...){
  ME <- colMeans(f$residuals)
  RMSE <- apply(f$residuals, MARGIN = 2,
                FUN = function(x){sqrt(sum(x ^ 2)/ length(x))})
  MAE <- colMeans(abs(f$residuals))
  results <- data.frame(ME, RMSE, MAE)
  rownames(results) <- paste("Forecast Horizon ", rownames(results))
  # MASE TODO
  # Will require actual/fitted/residuals
  return(results)
}


#' Print a summary of the hybridModel object
#'
#' @param x the input \code{hybridModel} object.
#' @details Print the names of the individual component models and their weights.
#'
#'
summary.hybridModel <- function(x){
  print(x)
}

#' Print information about the hybridModel object
#'
#' Print information about the \code{hybridModel} object.
#'
#' @param x the input \code{hybridModel} object.
#' @param ... other arguments (ignored).
#' @export
#' @details Print the names of the individual component models and their weights.
#'
print.hybridModel <- function(x, ...){
  #chkDots(...)
  cat("Hybrid forecast model comprised of the following models: ")
  cat(x$models, sep = ", ")
  cat("\n")
  for(i in x$models){
    cat("############\n")
    cat(i, "with weight", round(x$weights[i], 3), "\n")
  }
}

#' Plot a hybridModel object
#'
#' Plot a representation of the hybridModel.
#'
#' @method plot hybridModel
#' @import forecast
#' @param x an object of class hybridModel to plot.
#' @param type if \code{type = "fit"}, plot the original series and the individual fitted models.
#' If \code{type = "models"}, use the regular plot methods from the component models, i.e.
#' \code{\link[forecast]{plot.Arima}}, \code{\link[forecast]{plot.ets}},
#' \code{\link[forecast]{plot.tbats}}. Note: no plot
#' methods exist for \code{nnetar} and \code{stlm} objects, so these will not be plotted with
#' \code{type = "models"}.
#' @param ggplot should the \code{\link{autoplot}} function
#' be used (when available) for the plots?
#' @param ... other arguments passed to \link{plot}.
#' @seealso \code{\link{hybridModel}}
#' @return None. Function produces a plot.
#'
#' @details For \code{type = "fit"}, the original series is plotted in black.
#' Fitted values for the individual component models are plotted in other colors.
#' For \code{type = "models"}, each individual component model is plotted. Since
#' there is not plot method for \code{stlm} or \code{nnetar} objects, these component
#' models are not plotted.
#' @examples
#' \dontrun{
#' hm <- hybridModel(woolyrnq, models = "aenst")
#' plot(hm, type = "fit")
#' plot(hm, type = "models")
#' }
#' @export
#'
#' @author David Shaub
#' @importFrom ggplot2 ggplot aes autoplot geom_line scale_y_continuous
#'
plot.hybridModel <- function(x,
                             type = c("fit", "models"),
                             ggplot = FALSE,
                             ...){
   type <- match.arg(type)
   #chkDots(...)
   plotModels <- x$models
   if(type == "fit"){
      if(ggplot){
        plotFrame <- data.frame(matrix(0, nrow = length(x$x), ncol = 0))
        for(i in plotModels){
          plotFrame[i] <- fitted(x[[i]])
        }
        names(plotFrame) <- plotModels
        plotFrame$date <- as.Date(time(x$x))
        # Appease R CMD check for undeclared variable
        variable <- NULL
        value <- NULL
        # If anyone knows a cleaner way to transform this "wide" data to "long" data for plotting
        # with ggplot2 without using additional packages, let me know.
        pf <- matrix(as.matrix(plotFrame[, plotModels]), ncol = 1)
        pf <- data.frame(date = plotFrame$date,
                         variable = factor(rep(plotModels,
                                               each = nrow(plotFrame)),
                                           levels = plotModels),
                         value = pf)
        plotFrame <- pf[order(pf$variable, pf$date), ]
        ggplot(data = plotFrame,
               aes(x = date, y = as.numeric(value), col = variable)) +
        geom_line() + scale_y_continuous(name = "y")
         
      } else{
         # Set the highest and lowest axis scale
         ymax <- max(sapply(plotModels,
                            FUN = function(i) max(fitted(x[[i]]), na.rm = TRUE)))
         ymin <- min(sapply(plotModels,
                            FUN = function(i) min(fitted(x[[i]]), na.rm = TRUE)))
         range <- ymax - ymin
         plot(x$x, ylim = c(ymin - 0.05 * range, ymax + 0.25 * range), ...)
         #title(main = "Plot of original series (black) and fitted component models", outer = TRUE)
         for(i in seq_along(plotModels)){
            lines(fitted(x[[plotModels[i]]]), col = i + 1)
         }
         legend("top", plotModels, fill = 2:(length(plotModels) + 1), horiz = TRUE)
      }
   } else if(type == "models"){
      plotModels <- x$models[x$models != "stlm" & x$models != "nnetar"]
      for(i in seq_along(plotModels)){
         # bats, tbats, and nnetar aren't supported by autoplot
         if(ggplot && !(plotModels[i] %in% c("tbats", "bats", "nnetar"))){
            autoplot(x[[plotModels[i]]])
         } else if(!ggplot){
            plot(x[[plotModels[i]]])
         }
      }
   }
}
