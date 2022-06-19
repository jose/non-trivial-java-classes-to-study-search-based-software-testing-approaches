#
# This script selects a subset of classes for training/tuning, e.g., evolutionary
# algorithms, different configuration of evolutionary algorithms, etc.
#

PERCENTAGE_OF_CLASSES_FOR_TRAINING <- 0.10

#
# Return a boolean vector, where each position in respect to x is true if that
# element appear in y.
#
are_in_the_subset <- function(x, y) {
  # First consider vector with all FALSE
  result <- x!=x
  for (k in y) {
    result <- result | x==k
  }
  return(result)
}

df      <- read.csv('classes.csv', header=TRUE, stringsAsFactors=FALSE)
classes <- unique(df$'class')
n       <- floor(length(classes) * PERCENTAGE_OF_CLASSES_FOR_TRAINING)

training_set <- sample(classes, n, replace=FALSE)
testing_set  <- classes[! are_in_the_subset(classes, training_set)]

write.csv(df[df$'class' %in% training_set, ], file='classes-training.csv', quote=FALSE, row.names=FALSE)
write.csv(df[df$'class' %in% testing_set, ],  file='classes-testing.csv', quote=FALSE, row.names=FALSE)

# EOF

