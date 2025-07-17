/=  mine  /common/pow
/=  sp  /common/stark/prover
/=  *  /common/zoon
/=  *  /common/zeke
/=  *  /common/wrapper
=<  ((moat |) inner)
=>
  |%
  +$  mine-success
    $:  %command
        %pow
        =proof
        dig=tip5-hash-atom
        header=noun-digest:tip5
        nonce=noun-digest:tip5
    ==
  +$  effect  
    $%  [%mine-result (each [hash=noun-digest:tip5 mine-success] dig=noun-digest:tip5)]
        [%send wire=wire data=*]  :: 新增：发送消息到其他节点
        [%log message=@t]        :: 新增：日志输出
        [%reward miner-id=@ud]   :: 新增：发放奖励
        [%fork cord=@t vase=vase] :: 新增：启动异步线程
    ==
  +$  kernel-state  
    $:  %state
        version=%1
        miners=(map @ud miner-info)  :: 矿工ID到信息映射
        current-header=noun-digest:tip5  :: 当前区块头
        current-target=bignum:bignum    :: 当前难度目标
        master=?                       :: 是否为主节点
        master-wire=wire               :: 主节点连接（矿工专用）
        mining-thread=?                :: 挖矿线程状态
    ==
  +$  miner-info
    $:  wire=wire                    :: 矿工的网络连接
        pubkey=@ux                   :: 矿工公钥（用于奖励）
        hash-rate=@ud                :: 算力（哈希率）
    ==
  +$  cause  
    $%  [%0 header=noun-digest:tip5 nonce=noun-digest:tip5 target=bignum:bignum pow-len=@]
        [%1 header=noun-digest:tip5 nonce=noun-digest:tip5 target=bignum:bignum pow-len=@]
        [%2 header=noun-digest:tip5 nonce=noun-digest:tip5 target=bignum:bignum pow-len=@]
        [%new-block header=noun-digest:tip5]  :: 新增：新区块通知
        [%register-miner pubkey=@ux]          :: 新增：矿工注册
        [%submit-nonce miner-id=@ud nonce=@]  :: 新增：提交nonce
        [%new-header header=noun-digest:tip5 target=bignum:bignum]  :: 新增：新区块头
    ==
  --
|%
++  moat  (keep kernel-state) :: 状态容器
++  inner
  |_  k=kernel-state
  :: 初始化状态
  ++  load
    |=  =kernel-state  kernel-state
  :: 处理查询请求
  ++  peek
    |=  arg=*
    =/  pax  ((soft path) arg)
    ?~  pax  ~|(not-a-path+arg !!)
    ?+    pax  ~|(invalid-peek+pax !!)
        [%x %miners %status ~]
          `[[%miners (lent miners.k)]~]
    ==
  :: 核心：处理各种消息
  ++  poke
    |=  [wir=wire eny=@ our=@ux now=@da dat=*]
    ^-  [(list effect) k=kernel-state]
    =/  cause  ((soft cause) dat)
    ?~  cause
      ~>  %slog.[0 [%leaf "error: bad cause: {<dat>}"]]
      `k
    =/  cause  u.cause
    ?+    -.cause  `k
        :: 主节点收到新区块（来自网络或其他节点）
        %new-block
          :: 更新当前区块头
          =/  new-k  k(current-header header.cause)
          :: 广播给所有矿工
          =/  effects
            %-  %~  roll  miners.k
            |=  [id=@ud info=miner-info]
            [%send wire.info [%new-header header.cause current-target.k]]~
          :: 记录日志
          :_  new-k
          [[%log "Broadcast new header to {<(lent miners.k)>} miners"] effects]
        ::
        :: 矿工注册
        %register-miner
          :: 分配新矿工ID
          =/  new-id  (add 1 (lent miners.k))
          =/  new-miners  (~(put by miners.k) new-id [wir pubkey.cause 0])
          :_  k(miners new-miners)
          [[%log "Miner registered: ID={new-id}"]~]
        ::
        :: 处理矿工提交的nonce
        %submit-nonce
          :: 验证nonce有效性
          =/  input=prover-input:sp  [%0 current-header.k nonce.cause pow-len:mine]
          =/  [prf=proof:sp dig=tip5-hash-atom]  (prove-block-inner:mine input)
          ?.  (check-target:mine dig current-target.k)
            :_  k
            [[%log "Rejected nonce from miner {miner-id.cause}"]~]
          :: 发放奖励（效果）
          =/  reward-effect  [%reward miner-id.cause]
          :_  k
          [[%log "Block mined by miner {miner-id.cause}"] reward-effect]
        ::
        :: 矿工收到新区块头（来自主节点）
        %new-header
          :: 停止当前挖矿线程（如果正在运行）
          ?:  mining-thread.k
            :_  k(mining-thread %.n)
            [[%fork %stop-mining ~]~]
          :: 创建挖矿任务
          =/  task  [%0 header.cause 0 target.cause pow-len:mine]
          :_  k(current-header header.cause, current-target target.cause, mining-thread %.y)
          [[%fork %mining-thread !>(task)]~]
        ::
        :: 原挖矿任务（兼容）
        %0
        %1
        %2
          :: 如果是矿工节点且没有连接到主节点，直接处理
          ?:  &(master.k)  `k
          ?:  mining-thread.k
            :_  k
            [[%log "Mining already in progress, skipping new task"]~]
          :_  k(mining-thread %.y)
          [[%fork %mining-thread !>(cause)]~]
    ==
  ::
  :: 异步挖矿线程
  ++  task
    |=  [=wire =cord =vase]
    ?+  cord  ~
        %mining-thread
          =/  task  !<  cause  vase
          ?-  -.task
            %0
              =/  nonce  nonce.task
              =/  input=prover-input:sp  [%0 header.task nonce pow-len.task]
              =/  [prf=proof:sp dig=tip5-hash-atom]  (prove-block-inner:mine input)
              ?:  (check-target:mine dig target.task)
                :: 找到有效nonce，提交给主节点
                :_  ~
                [[%send master-wire.k [%submit-nonce [our.k nonce]]]~]
              :: 未找到，继续尝试下一个nonce
              :_  ~
              [[%fork %mining-thread !>([%0 header.task (add nonce 1) target.task pow-len.task])]~]
            ::
            %1
            %2
              :: 类似处理...
          ==
        ::
        %stop-mining
          ~  :: 停止挖矿线程
    ==
--
