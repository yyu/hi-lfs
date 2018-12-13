#!/bin/bash

f=$1

(echo 'cat > '$f' << "EEEEEOF"' && \
 cat $f                         && \
 echo 'EEEEEOF'                 && \
 echo                           && \
 echo -n '. '$f                    \
) | pbcopy
