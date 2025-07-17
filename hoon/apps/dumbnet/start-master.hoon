/-  master-node
=>
  |%
  ++  kick  |=(* ~)
  ++  main
    |=  [~ ~]
    ^-  (list move)
    :_  ~
    [%pass /init %arvo %e %init /master [%master %yes]]~
  --
|_  ~
++  poke-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip move _..main)
  ?+    sign-arvo  [~ +>.$]
      [%e %init %master state=kernel-state:master-node]
        ~&  [%master-started state]
        [~ +>.$(..main state)]
      [%e %fact =cage]
        ~&  [%master-event cage]
        [~ +>.$]
  ==
