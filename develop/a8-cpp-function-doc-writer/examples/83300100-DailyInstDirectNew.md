# 83300100-DailyInstDirectNew

## Summary

- `83300100` 由 `DailyInstDirectNew` 作为导出入口，负责接收指令下达/修改请求，解包输入参数，按市场和业务路由把请求分发到股票、银行间、票据或场外原子流程。
- 当前文档重点展开 `BUSINESS_STK` 路径，即 `AtomInstrStkDirect -> CInstrStkBusinessFlow -> CInstrStkBusiMgr -> CInstrBusinessBase` 这条主链，并说明 `0B/0S` 两个常见证券买卖分支的底层处理。

## Involved tables

- 读取表（主流程）
  - `rtcm_sysconfig`
    - `InitSysconfigBase -> CRtcm_sysconfigManager`，见 `lbm/public/trdbase.h:89`
  - `rtcm_stock`
    - `GetAcctInfo -> QueryStock -> CRtcm_stockManager`，见 `lbm/public/instr_public.h:89`、`lbm/public_utility/busiutility_qry_stock.h:104`
  - `rtcm_stocksub`
    - `InitCacheStocksub -> QueryStocksub -> CRtcm_stocksubManager`，见 `lbm/public/trddataindex.h:81`、`lbm/public_utility/busiutility_qry_stock.h:151`
  - `rtcm_secuid`
    - `GetAcctInfo/InitCacheSecuid -> QuerySecuid -> CRtcm_secuidManager`，见 `lbm/public/instr_public.h:109`、`lbm/public/trddataindex.h:95`、`lbm/public_utility/busiutility_qry_acct.h:369`
  - `rtcm_projectacct`
    - `GetAcctInfo/InitCacheProjectacct -> QueryProjectacct -> CRtcm_projectacctManager`，见 `lbm/public/instr_public.h:126`、`lbm/public/trddataindex.h:98`、`lbm/public_utility/busiutility_qry_acct.h:413`
  - `rtcm_fundacctlink`
    - `GetAcctInfo/InitCacheFundacctlink -> QueryFundacctlink -> CRtcm_fundacctlinkManager`，见 `lbm/public/instr_public.h:137`、`lbm/public/trddataindex.h:102`、`lbm/public_utility/busiutility_qry_acct.h:458`
  - `rtcm_fundacct`
    - `InitCacheFundacct -> QueryFundacct -> CRtcm_fundacctManager`，见 `lbm/public/trddataindex.h:106`、`lbm/public_utility/busiutility_qry_acct.h:775`
  - `rtcm_bsconfig`
    - `InitCacheBsconfig -> QueryBsconfig -> CRtcm_bsconfigManager`，见 `lbm/public/trddataindex.h:68`、`lbm/public/trddataindex.h:192`、`lbm/public_utility/busiutility_qry_param.h:101`
  - `rtcm_fund`
    - `InitCacheFund -> QueryFund -> CRtcm_fundManager`，见 `lbm/public/trddataindex.h:71`、`lbm/public/trddataindex.h:373`、`lbm/public_utility/busiutility_qry_fund.h:45`
  - `rtcm_fundctrl`
    - `InitCacheAvlctrlmodel -> QueryAvlctrlmodel -> CRtcm_fundctrlManager`，见 `lbm/public/trddataindex.h:73`、`lbm/public_utility/busiutility_qry_fund.h:97`
  - `rtcm_avlctrlmodel`
    - `InitCacheAvlctrlmodel -> QueryAvlctrlmodel -> CRtcm_avlctrlmodelManager`，见 `lbm/public/trddataindex.h:73`、`lbm/public_utility/busiutility_qry_fund.h:94`
  - `rtcm_comb`
    - `InitCacheComb -> QueryComb -> CRtcm_combManager`，见 `lbm/public/trddataindex.h:109`、`lbm/public_utility/busiutility_qry_acct.h:596`
  - `rtcm_market`
    - `InitCacheMarket -> QueryMarket -> CRtcm_marketManager`，见 `lbm/public/trddataindex.h:115`、`lbm/public_utility/busiutility_qry_stock.h:286`
  - `rtcm_seat`
    - `InitCacheSeat -> QuerySeat -> CRtcm_seatManager`，见 `lbm/public/trddataindex.h:118`、`lbm/public_utility/busiutility_qry_offer.h:164`
  - `rtcm_hk_exrate`（条件读取）
    - `InitCacheHkExrate -> QueryHk_exrate -> CRtcm_hk_exrateManager`，见 `lbm/public/trddataindex.h:121`、`lbm/public_utility/busiutility_qry_ggt.h:43`
  - `rtfa_projectasset`
    - `InitCacheProjectasset -> QueryProjectasset -> CRtfa_projectassetManager`，见 `lbm/public/trddataindex.h:99`、`lbm/public_utility/busiutility_qry_asset.h:177`
  - `rtfa_combstkbal`
    - `InitCacheCombstkbal -> QueryCombstkbal -> CRtfa_combstkbalManager`，见 `lbm/public/trddataindex.h:112`、`lbm/public_utility/busiutility_qry_asset.h:154`
  - `rtfa_instruction`（条件读取：修改指令等需要旧指令上下文）
    - `InitCacheInstruction -> QueryInstruction -> CRtfa_instructionManager`，见 `lbm/public/trddataindex.h:492`、`lbm/public_utility/busiutility_qry_instr.h:62`
  - `rtfa_instructstock`（条件读取：修改指令等需要旧指令证券明细）
    - `InitCacheInstructstock -> QueryInstructstock -> CRtfa_instructstockManager`，见 `lbm/public/trddataindex.h:501`、`lbm/public_utility/busiutility_qry_instr.h:107`
  - `rtfa_asset_log_preins`
    - `ProcessInquiryCancelDeal -> QueryPreinsAssetChg -> CRtfa_asset_log_preinsManager`，见 `lbm/atom_public/process_inquiry_cancel.h:77`、`lbm/public_utility/busiutility_qry_asset.h:506`
  - `rtfa_stkbal_log_preins`
    - `ProcessInquiryCancelDeal -> QueryPreinsSkbalChg -> CRtfa_stkbal_log_preinsManager`，见 `lbm/atom_public/process_inquiry_cancel.h:98`、`lbm/public_utility/busiutility_qry_asset.h:517`
  - `rtfa_inquirelog`
    - `QueryInquirelog -> CRtfa_inquirelogManager`，见 `lbm/public_utility/busiutility_qry_acct.h:690`

- 写入表（主流程）
  - `rtfa_instruction`
    - `WriteCacheDataInstruction -> writetable_instruction_insert/update -> CRtfa_instructionManager`，见 `lbm/atom_public/instrdata.h:356`、`lbm/public_utility/busiutility_write_instr.h:79`
  - `rtfa_instructstock`
    - `WriteCacheDataInstructStock -> writetable_instructstock_insert/update -> CRtfa_instructstockManager`，见 `lbm/atom_public/instrdata.h:381`、`lbm/public_utility/busiutility_write_instr.h:90`
  - `rtfa_projectasset`
    - `WriteCacheDataProjectasset -> writetable_instrprojectasset_delta -> CRtfa_projectassetManager`，见 `lbm/atom_public/instrdata.h:668`、`lbm/public_utility/busiutility_write_asset.h:70`
  - `rtfa_combstkbal`
    - `WriteCacheDataCombstkbal -> writetable_instrcombstkbal_delta -> CRtfa_combstkbalManager`，见 `lbm/atom_public/instrdata.h:677`、`lbm/public_utility/busiutility_write_asset.h:48`
  - `rtfa_asset_log_preins`
    - `WriteCacheDataPreinsAssetChg -> writetable_inquiryassetlog_delta -> CRtfa_asset_log_preinsManager`，见 `lbm/atom_public/instrdata.h:688`、`lbm/public_utility/busiutility_write_asset.h:191`
  - `rtfa_stkbal_log_preins`
    - `WriteCacheDataPreinsStkbalChg -> writetable_inquirystkballog_delta -> CRtfa_stkbal_log_preinsManager`，见 `lbm/atom_public/instrdata.h:697`、`lbm/public_utility/busiutility_write_asset.h:202`
  - `rtfa_projectasset_preins`
    - `WriteCacheDataPreinsProjectasset -> writetable_projectasset_preins_delta -> CRtfa_projectasset_preinsManager`，见 `lbm/atom_public/instrdata.h:706`、`lbm/public_utility/busiutility_write_asset.h:233`
  - `rtfa_combstkbal_preins`
    - `WriteCacheDataPreinsCombstkbal -> writetable_combstkbal_preins_delta -> CRtfa_combstkbal_preinsManager`，见 `lbm/atom_public/instrdata.h:715`、`lbm/public_utility/busiutility_write_asset.h:244`
  - `rtfa_inquirelog`
    - `WriteCacheDataInquirelog -> writetable_inquirelog_insert/update -> CRtfa_inquirelogManager`，见 `lbm/atom_public/instrdata.h:481`、`lbm/public_utility/busiutility_write_trade.h:39`
  - `rtfa_blocksalestat`
    - `WriteCacheBlockSaleStat -> CRtfa_blocksalestatManager`，见 `lbm/atom_public/instrdata.h:368`
  - `rtfa_tradeqtyamt`
    - `Writetable_rtfa_tradeqtyamt -> CProcessDealTradeqtyamt::writetable_rtfa_tradeqtyamt -> CRtfa_tradeqtyamtManager`，见 `lbm/atom_public/instrdata.h:1446`、`lbm/atom_public/process_deal_tradeqtyamt.h:85`
  - `rtfa_lockstkbal`
    - `Writetable_rtfa_lockstkbal -> CProcessDealLockstkbal::writetable_rtfa_lockstkbal -> CRtfa_lockstkbalManager`，见 `lbm/atom_public/instrdata.h:1451`、`lbm/atom_public/process_deal_lockstkbal.h:108`

## Involved macros / enums

- `BUSINESS_STK` / `BUSINESS_OUT` / `BUSINESS_BANK` / `BUSINESS_BILL` / `BUSINESS_NULL` -> `lbm/atom_public/atomroute.h:32-36`；内容分别是 `1/2/3/4/0`，`CAtomRoute::GetBusinessRoute(...)` 用它们表达股票、场外、银行间、票据和空路由。
- `BUS_FLAG_INS_DIRI` / `BUS_FLAG_INS_MODI` -> `comm/trddefine.h:1752,1756`；内容分别是 `40103` 和 `40201`，表示指令新下达和指令修改。
- `INSTR_BUSIFLAG_NOTCHECK_FUND` -> `comm/trddefine.h:1761`；内容是 `'1'`，表示指令业务标志里命中该位时可跳过资金可用校验。
- `MARKET_STK(MARKET)` -> `comm/trddefine.h:35`；内容是 `((JSTP_STRCMP(MARKET,MKT_SHANGHAIA)==0) || (JSTP_STRCMP(MARKET,MKT_SHENZHENA)==0))`，把沪深 A 股市场归为股票业务。
- `MARKET_HK_STK(MARKET)` -> `comm/trddefine.h:39`；内容是 `(JSTP_STRCMP(MARKET,MKT_GGT) ==0  || JSTP_STRCMP(MARKET,MKT_SGT)==0)`，把港股通市场归为股票业务。
- `MARKET_OUT(MARKET)` -> `comm/trddefine.h:41`；内容是 `(JSTP_STRCMP(MARKET,MKT_OUTMARKET) ==0)`，把场外市场归为场外业务。
- `BSFLAG_0B` / `BSFLAG_0S` -> `comm/trddefine.h:456-457`；内容分别是 `"0B"` 和 `"0S"`，当前主文档展开的就是证券买入和证券卖出两条分支。
- `IN_KGBP_PLATFORM` / `IN_JSTP_PLATFORM` -> `lbm/public/trdbase.h:43-49`；这里不是数值常量，而是编译期开关，代码通过 `#if defined IN_KGBP_PLATFORM` / `#elif defined IN_JSTP_PLATFORM` 选择包含 `kgbptrdbase.h` 或 `jstptrdbase.h`。
- `JSTP_LBM_TRY` / `JSTP_LBM_CATCH`、`JSTPX_LOCK_TRY` / `JSTPX_LOCK_FINALLY`、`JSTP_LOCK_TRY` / `JSTP_LOCK_FINALLY` -> 当前文档把它们当作控制流宏看待；它们分别包住外部接口异常保护、LBM 句柄级锁和交易锁范围。

## Entry

- `EXPORT_LBM_FUNC(DailyInstDirectNew)` -> `function/lbm_rtfa_instr/lbm_export.h:35` 声明导出函数名，供外部按功能号 `83300100` 调用。
- `LBM_IMPLEMENT_EXT(CStkInstrBusiness, DailyInstDirectNew)` -> `function/lbm_rtfa_instr/lbm_export.cpp:8` 把导出函数绑定到 `CStkInstrBusiness::DailyInstDirectNew`。
- `void DailyInstDirectNew(char *pCA)` -> `function/lbm_rtfa_instr/stk_instr_business.h:61` 作为实际入口，进入 LBM 异常保护宏后调用 `RunNew()`。

## Procedure

- `void DailyInstDirectNew(char *pCA)` -> `function/lbm_rtfa_instr/stk_instr_business.h:61` 作为 83300100 的入口包装，进入 `JSTP_LBM_TRY/JSTP_LBM_CATCH` 保护后调用 `RunNew()`。
- `RunNew()` -> `function/lbm_rtfa_instr/stk_instr_business.h:92` 创建 `CKamcCommInstr`，把 LBM 输入解包到 `m_objInstrDirectParam`，获取线程池句柄，执行业务主流程，最后把返回结果重新组装为 LBM 输出字段和结果集。
  - `CKamcCommInstr objStkCommInstr(this)` -> `function/lbm_rtfa_instr/stk_instr_business.h:95` 构造解包辅助对象，后续所有入参读取都通过它完成。
  - `objStkCommInstr.DailyInstNewDirInit(m_objInstrDirectParam)` -> `function/lbm_rtfa_instr/stk_instr_business.h:96` 解出指令头字段、证券明细包和若干附加业务包，填充 `CInstrDirectParam`。
  - `GetThreadPoolHandle()` -> `function/lbm_rtfa_instr/stk_instr_business.h:99` 取线程池/平台句柄，供后续原子流程和时间、锁、回调逻辑使用。
  - `RunBusiness(objStkCommInstr)` -> `function/lbm_rtfa_instr/stk_instr_business.h:102` 在 `JSTPX_LOCK_TRY/JSTPX_LOCK_FINALLY` 范围内执行实际路由。
  - `objStkCommInstr.InstrResultSet(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:111` 根据 `m_objInstrDirectParam` 中已经写回的结果字段拼接返回消息。
  - `MakeSingleResultSetMacro(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:113` 输出 `outInsSno/outInsModSno/insSno/insModSno/insDate/remark` 六列结果。

- `CKamcCommInstr::DailyInstNewDirInit(...)` -> `function/public_rtfa/rtfa_comm_instr.h:46` 从输入包读取指令头字段，解析 `insScrPack` 中的每一行证券数据，回填 `m_vInstructstockParam`，并按需要加载附加包。
  - 读取 `insFlag` 并把 `"01"` 映射为 `BUS_FLAG_INS_DIRI`、`"02"` 映射为 `BUS_FLAG_INS_MODI` -> `function/public_rtfa/rtfa_comm_instr.h:53-62`。
  - 读取 `insScrPack` 原始包体并校验长度不能为 0 -> `function/public_rtfa/rtfa_comm_instr.h:78-84`。
  - `CCommPackOp` 打开 BP 包并逐行 `RsFetchRow()` -> `function/public_rtfa/rtfa_comm_instr.h:86-90`。
  - 每行读取 `productId/projectId/combId/schemeId/secuid/seatNo/mktCode/scrCode/bsflag/insPrice/insQty/insAmt/clearSpd` 等字段 -> `function/public_rtfa/rtfa_comm_instr.h:99-146`。
  - 当有对手证券字段时调用 `JstpGetStockId(...)` 计算 `m_szRivalScrId`；部分 `7M/7N` 分支会改写 `m_szRivalScrId` 或 `m_szBsflag` -> `function/public_rtfa/rtfa_comm_instr.h:148-164`。
  - 记录一条完整参数日志，并把 `objInstructStockParam` push 进 `m_vInstructstockParam` -> `function/public_rtfa/rtfa_comm_instr.h:166-180`。
  - 如果存在 `trdBodyPack`、`underAppInqPack`、`optAlgoPack`、`pledgePack` 等附加包，会继续调用对应 `Init...Data` 方法写入 `CInstrDirectParam` 的附加结构 -> `function/public_rtfa/rtfa_comm_instr.h:184` 之后。

- `RunBusiness(CKamcCommInstr &objStkCommInstr)` -> `function/lbm_rtfa_instr/stk_instr_business.h:146` 在 LBM 句柄级锁内调用 `CallJstpx()`，把请求送进原子业务流程。

- `CallJstpx(CKamcCommInstr &objStkCommInstr)` -> `function/lbm_rtfa_instr/stk_instr_business.h:153` 先把 `m_vcInterfacePack` 绑定到 `m_objInstrDirectParam.m_pvcInterfacePack`，再按市场和业务类型选择原子入口。
  - `CAtomRoute::GetBusinessRoute(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:156`, `lbm/atom_public/atomroute.h:46` 根据 `mktCode + bsflag + cInsBusiClass` 返回 `BUSINESS_STK/BUSINESS_BANK/BUSINESS_BILL/BUSINESS_OUT`。
  - `AtomInstrStkDirect(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:159` 股票类路由进入股票原子指令流程。
  - `AtomInstrBankDirect(...)` / `AtomInstrBillDirect(...)` / `AtomInstrOutDirect(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:163/167/171` 分别把请求送到银行间、票据、场外原子流程；当前文档不继续展开这三条支路。
  - `CSendMsgToRisk::SendRiskMsg(...)` -> `function/lbm_rtfa_instr/stk_instr_business.h:179` 在原子流程返回后，把接口包推送给风控侧。

- `CAtomRoute::GetBusinessRoute(...)` -> `lbm/atom_public/atomroute.h:46` 先按若干 `bsflag` 特例做业务分流，再按市场宏归类。
  - `BSFLAG_2C/CB/CS/0H(bank)/0z/2n/...` 直接归 `BUSINESS_OUT` -> `lbm/atom_public/atomroute.h:49-65`。
  - `BSFLAG_03/04/05/13/14/15` 结合 `cBusiness` 决定走 `BUSINESS_OUT` 还是 `BUSINESS_STK` -> `lbm/atom_public/atomroute.h:67-82`。
  - `MARKET_STK/HK_STK/FUTURE/THIRD/BJS` 统一归 `BUSINESS_STK` -> `lbm/atom_public/atomroute.h:94-101`。
  - `MARKET_OUT/OTC` 归 `BUSINESS_OUT`，`MARKET_BANK` 归 `BUSINESS_BANK`，`MARKET_BILL` 归 `BUSINESS_BILL` -> `lbm/atom_public/atomroute.h:103-118`。

- `AtomInstrStkDirect(...)` -> `lbm/atom_rtfa_instruction_stk/atom_instr_stk_export.cpp:4` 校验传入参数结构长度后，构造 `CInstrStkBusinessFlow` 并执行 `AtomInstrDirectExt()`。
  - `STRUCTAtomRaiseException(...)` -> `lbm/atom_rtfa_instruction_stk/atom_instr_stk_export.cpp:6` 校验入参指针和长度与 `CInstrDirectParam` 一致。
  - `CInstrStkBusinessFlow objInstrBusinessFlow(...)` -> `lbm/atom_rtfa_instruction_stk/atom_instr_stk_export.cpp:8` 创建股票指令业务流对象。
  - `objInstrBusinessFlow.AtomInstrDirectExt(pInstrDirectParam)` -> `lbm/atom_rtfa_instruction_stk/atom_instr_stk_export.cpp:9` 把请求正式送入股票指令主流程。

- `CInstrBusinessFlow::AtomInstrDirectExt(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:55` 保存 `m_pInstrParam` 并调用 `RunBusinessMain()`。

- `RunBusinessMain()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:72` 先做与具体证券无关的初始化，再进入交易锁，根据 `m_nInstrflag` 选择“新下达”还是“修改”路径。
  - `InitInstrBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:164` 读取系统状态、获取物理时间、校验证券明细不为空，并初始化 `CInstrData` 的基础上下文。
  - `JSTP_LOCK_TRY()` / `JSTP_LOCK_FINALLY(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:77,90` 在交易锁内执行指令流程。
  - `BUS_FLAG_INS_DIRI -> RunInstrBusinessDirect()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:80-82` 当前 83300100 常见新下达路径。
  - `BUS_FLAG_INS_MODI -> RunInstrBusinessDirectModi()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:83-85` 修改路径会先加载旧指令和旧指令证券。

- `InitInstrBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:164` 做所有证券共用的初始化。
  - `InitSysconfigBase()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:166`, `lbm/public/trdbase.h:89` 读取 `rtcm_sysconfig` 第一条记录，缓存到 `m_pSysconfigBase`，并要求 `run_status == '0'`。
  - `m_nPhyTime = get_current_time(m_hPlatform)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:168` 取当前物理时间，后续作为默认指令时间。
  - `m_pInstrParam->m_vInstructstockParam.size() <= 0` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:171` 如果没有任何证券明细，直接抛错。
  - `m_objInstrData.InitData(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:176`, `lbm/atom_public/instrdata.h:177` 把 `CInstrDirectParam`、`CTrdDataIDX`、系统配置、流程标志和物理时间绑定到 `CInstrData`。

- `RunInstrBusinessDirect()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:120` 顺序执行下达流程的五个阶段。
  - `InitInstructionParam()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:124` 调用 `CInstrData::InitInstruct()` 给指令对象补默认状态、日期、时间和业务属性。
  - `RunDirectBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:125` 进入逐证券的业务处理主循环。
  - `InitInstructAllData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:126` 生成指令号并初始化附属结构。
  - `WriteBusinessData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:127` 把指令相关缓存写回表。
  - `AfterInstrCallBack()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:128` 把结果打包给风控接口。

- `RunInstrBusinessDirectModi()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:132` 是修改指令主链，执行顺序与新下达不同：
  - `InitInstrBusinessParamU()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:180` 先调用 `CInstrData::InitInstrBusinessParamU()` 加载旧版本上下文。
    - `QueryInstruction(insSno, insModSno, insDate)` -> `lbm/atom_public/instrdata.h:205`, `lbm/public_utility/busiutility_qry_instr.h:62` 按旧指令主键查 `rtfa_instruction`；未命中直接抛异常。
    - `QueryInstructstockV(insSno, insModSno, insDate)` -> `lbm/atom_public/instrdata.h:213`, `lbm/public_utility/busiutility_qry_instr.h:145` 按旧指令主键查整组 `rtfa_instructstock`；未命中直接抛异常。
    - `DEFINE_INSTRUCTSTOCK_KEY` -> `lbm/atom_public/instrdata.h:223`, `lbm/atom_public/atominstrparam.h:5` 把每条旧证券拼成 `insSno|insModSno|scrId|bsflag`，建立 `m_mOldInstructStkIDX`，供后续“新旧证券对位”直接查索引。
    - `InitInstructionParamU()` -> `lbm/atom_public/instrdata.h:1216` 把旧指令的业务属性和状态字段（`insType/insBusiClass/insScrCtrlType/ordFinishStatus/matchFinishStatus/clearSpd/...`）回填到本次请求，并将 `insTime` 刷为当前物理时间。
    - `InitInstructStockParamU()` -> `lbm/atom_public/instrdata.h:1246` 对当前请求证券逐条 `JstpGetStockId(...)` 标准化后，用上面的 key 回查旧证券并回填累计委托/成交、状态、控制字段、账户席位与 `scrName` 等关键字段，保证修改流程在“旧状态基线”上重算净变动。
  - `RunDirectBusiness()` 按“新入参证券集合”重跑一遍业务计算，生成本次修改的净影响。
  - `ResetInsStatusParamU()` 重新汇总指令层委托/成交完成状态，避免沿用旧状态。
  - `InitInstructAllData() -> WriteBusinessData() -> AfterInstrCallBack()` 再按统一写表/回调链路落库与回传。

- `InitInstructAllData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:95` 负责“指令号体系 + 附属结构初始化”。
  - `InitInsSnoParam()` 根据 `instrflag` 生成或继承 `insSno/insModSno`，并回填到每个 `instructstock` 记录。
  - 普通新下达/修改/触发路径调用 `InitInstructDirect()` 初始化各附属向量（质押、ETF、回购、票据、场外期权等）；预指令路径调用 `InitPreInstructDirect()`。
  - 修改指令场景下，`insSno` 继承旧指令，`insModSno = oldInsModSno + 1`，保证版本号单调递增。
  - 按当前代码字面行为，`BUS_FLAG_INS_DIRI` 分支里的 `if (m_nInsSno = 0)` 是赋值表达式，因此会进入“重新取号”路径并把 `insModSno` 置 0；文档按代码现状记录，不推断作者意图 -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:197-204`。

- `ResetInsStatusParamU()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:393` 逐证券汇总 `ordFinishStatus/matchFinishStatus`，再回写指令头整体状态，保证修改路径下主表状态和明细状态一致。

- `AfterInstrCallBack()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:145` 只有 `m_pvcInterfacePack` 非空才回调；回调打包器按 `IsNeedSendBinary(...)` 在 `CFixInterfaceToRiskcontrolKgbp` 与 `CFixInterfaceToRiskcontrol` 两种实现之间切换。

- `CInstrData::InitInstruct()` -> `lbm/atom_public/instrdata.h:844` 对指令主对象补默认状态和时间。
  - 设置 `m_cInsStatus = INS_VALID`、`m_cLockFlag = NO_LOCK` -> `lbm/atom_public/instrdata.h:847-849`。
  - 若未给定委托完成状态/成交完成状态，则默认设为 `NO_ORDER/NO_DEAL` -> `lbm/atom_public/instrdata.h:850-853`。
  - 若 `insDate/insTime` 没传，则使用系统日和物理时间 -> `lbm/atom_public/instrdata.h:855-856`。
  - 若业务类别或证券控制类型为空，则根据 `mktCode + bsflag + insType` 推导默认值 -> `lbm/atom_public/instrdata.h:858-863`。

- `RunDirectBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:241` 逐个证券执行直接业务处理。
  - `RunDirectInit()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:244,271` 把 `m_objCal/m_objInstrData/m_pInstrParam/m_pSysconfigBase/m_objTrdIDX/m_objVal` 绑定到 `m_stTransParam`。
  - `RunDirectVaild()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:247,286` 当前为空实现，不增加额外校验。
  - 循环 `m_vInstructstockParam` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:249`，对每个证券：
    - 统一产品编号和指令日期 -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:251-252`。
    - 让 `m_stTransParam.m_pStockParam` 指向当前证券 -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:254-255`。
    - `CAtomDeal::ConvertClearspeed(...)` 计算清算速度，并回写到指令头和证券对象 -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:257-258`。
    - `RunDirectByMktcode(cFlag)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:260` 把当前证券送入按市场/业务类别选择出的实际业务类。
    - `RunDealTradeQtyAmt()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:261` 生成 `rtfa_tradeqtyamt` 增量：
      - 新下达直接取当前 `insQty/insAmt/spanMktReplaceAmt`；
      - 修改指令会先按 `instructstock key` 找旧记录并取差量（新-旧）；
      - 某些 `bsflag+specialBusiFlag` 组合直接跳过；
      - 最终调用 `InitRtfa_tradeqtyamt_Instr(...)` 进入缓存，后续写表时按主键“存在则 DeltaUpdate，不存在则 Insert”落地。
    - `RunDealLockStkbal()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:262` 生成 `rtfa_lockstkbal` 增量：
      - 仅对满足“特定 `bsflag` 且 `specialBusiFlag` 命中”条件的场景生效，其余直接返回；
      - 修改指令同样按旧指令证券做数量差量；
      - 调 `DealRtfa_lockstkbal_limit(...)` 生成缓存，后续写表时按主键选择 `insert` 或 `delta update`。

- `CInstrStkBusinessFlow::RunDirectByMktcode(...)` -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_flow.h:42` 构造 `CInstrStkBusiMgr`，把 `m_stTransParam` 交给它，再执行股票业务管理器。

- `CInstrStkBusiMgr::RunDirect(...)` -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_business_mgr.h:58` 先确认当前市场属于股票类可处理范围，然后通过工厂方法生成实际业务类。
  - `CreateInstance(m_pTransParam->m_pStockParam)` -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_business_mgr.h:68,85` 根据 `bsflag` 返回不同的 `CInstrBusinessBase` 子类实例。
  - `0A-0K` 大写区间返回 `CInstrDirBsflag0A_0K_upp`，`0L-0Z` 大写区间返回 `CInstrDirBsflag0L_0Z_upp`；此外还有 `00-09/0a-0z/10-1z/1a-...` 等区间映射到各自子类 -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_business_mgr.h:87-122`。
  - `m_lpInstrBusinessBase->InitData(m_pTransParam)` -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_business_mgr.h:75` 把交易上下文全部绑定到业务对象。
  - `m_lpInstrBusinessBase->RunDirect(cFlag)` -> `lbm/atom_rtfa_instruction_stk/instr_stk_direct_business_mgr.h:76` 虽然静态类型是父类指针 `CInstrBusinessBase*`，但后续 `DoDirectBusiness()` 等虚函数会按运行时真实子类分派；因此不能只看父类默认实现，必须跟到 `CreateInstance()` 返回的具体子类再判断真实逻辑。

- `CInstrBusinessBase::InitData(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:51` 复制 `m_pVal/m_pCal/m_pTrdIDX/m_pSysconfig/m_pInstrData/m_pStockParam/m_pInstrParam` 到成员变量，并初始化 `m_objInstrUtli`。

- `CInstrBusinessBase::RunDirect(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:66` 用统一顺序执行证券业务处理。
  - `InitDirectBase()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:71,112` 校验市场/买卖方向/证券代码，补账户信息，加载缓存，并初始化计算器、校验器和数据对象。
  - `DoDirectStockVaild()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:74,207` 当前基类为空；是否有实质逻辑取决于子类是否 override。
  - `InitDirectStockParam()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:77,153` 按 `instrflag + avlctrlmodel + instrBusiflag` 决定当前证券是否需要做资金/持仓可用校验，并在非修改流程初始化指令证券结构。
    - 预指令分支（`BUS_FLAG_PRE_DIRI/PRE_MODI`）看 `m_pTrdIDX->m_objCache.m_pAvlctrlmodel->m_szCashCtrlPoint/m_szScrCtrlPoint` 是否包含字符 `'1'`；不包含则分别把 `m_bIfNeedCheckAmt`、`m_bIfNeedCheckQty` 置 `false`。
    - 指令分支（`BUS_FLAG_INS_ACT/INS_DIRI/INS_MODI/READY_CHK`）看同样两个控制串是否包含字符 `'2'`；不包含则关闭对应校验。
    - 仅当不是 `BUS_FLAG_INS_MODI` 时才调用 `CInstrData::InitInstructStock(...)` -> `lbm/atom_public/instrdata.h:768`，初始化 `status/cashCtrlMtd/scrCtrlMtd/capitaldirect/shareChangeDirect/insSno/insModSno/insDate/modDate/exrate` 等基础字段；修改流程不重置这些字段，避免覆盖旧指令累计状态。
    - 若 `m_szInstrBusiflag` 命中 `INSTR_BUSIFLAG_NOTCHECK_FUND('1')`，会强制把 `m_bIfNeedCheckAmt` 置 `false`，即使控制模型允许资金校验也跳过。
    - 无论哪条分支，最后都会把 `m_pTrdIDX->m_objCache.m_pStock->m_szScrName` 回填到当前证券参数，确保后续写表/日志名称一致。
  - `DoDirectBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:80,219` 这里是实际业务差异点，真正执行的是子类 override。
  - `DoAfterDirectBusiness()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:83` 当前为空。
  - `DoDirectBusinessHold()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:243` 先根据 `mktCode + bsflag + cInsBusiClass` 再算一次业务路由；股票路径进入 `CInstrUtillHold::chkbusiness_stkhold_available(...)`，继续做老指令数量回补、减持额度校验和持仓可用校验。
  - `DoDirectPridictfee()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:415` 直接调用 `CInstrUtilFee::calbusiness_pridictfee()` 计算预测费用，并把结果回写到 `m_dbPredictFee`。
  - `DoDirectfundasset()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:384` 股票路径进入 `CInstrUtilFund::cal_fundasset_available()`，先算本次指令占用金额，再按“修改指令 / 新下达指令”修正已冻结和已委托部分。
  - `DealDirectData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:334` 先用 `SetInstrStockAmt(...)` 回写本条指令证券的冻结金额，再进入 `CProcessInsManager::ProcessInstrDealEx(...)`，把资金、持仓、资产变动记录整理到 `m_stInstrCapital`。
  - `DealInquiryData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:363` 只有 `m_nPreInsSno > 0` 时才进入 `CProcessInquiryCancel::ProcessInquiryCancelDeal(...)`，把前置询价的资产/持仓变动状态更新为“已接受”并生成反向记账数据。
  - `DoDirectBusinessFund()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:274` 先过滤“无需校验资金”的场景，股票路径再进入 `CInstrUtilFund::chkbusiness_fundasset_available(...)`，用本次总占用金额和资产单元可用资金做最终比较。

- `InitDirectBase()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:112` 是后续几乎所有叶子逻辑的前置条件。
  - 校验 `m_szMktCode/m_szBsflag/m_szScrCode` 不能为空 -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:115-122`。
  - `CInstrPbulic::GetAcctInfo(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:126`, `lbm/public/instr_public.h:79` 从证券、股东账户、资产单元和资金账号关系中补齐 `fundacct/secuid/seatNo/mainseat/trdPositionDirect` 等关键信息。
  - `m_pTrdIDX->InitCacheByQuery(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:132`, `lbm/public/trddataindex.h:61` 依序加载 `bsconfig/fund/avlctrlmodel/stock/stocksub/secuid/projectacct/projectasset/fundacctlink/fundacct/comb/combstkbal/market/seat/...` 等缓存。
  - `get_current_time(m_hPlatform)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:135` 刷新当前物理时间。
  - `m_pCal->InitData(...)` / `m_pVal->InitData(...)` / `m_objInstrUtli.InitData(m_pBsconfig)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:137-142` 初始化报价计算、业务校验和工具对象的依赖。

- `CInstrPbulic::GetAcctInfo(...)` -> `lbm/public/instr_public.h:79` 根据证券、资产单元和账户关系补账户字段。
  - 入口短路：当 `seatNo == "JJDX_SEAT"` 时直接返回，不再做账户补全 -> `lbm/public/instr_public.h:81-82`。
  - `CBusiQryStock::QueryStock(...)` -> `lbm/public/instr_public.h:89`, `lbm/public_utility/busiutility_qry_stock.h:104` 先按 `scrCode+mktCode` 查 `rtcm_stock`，并把查到的标准化 `mktCode/scrCode` 回写到请求对象。
  - `CONVERT_ALL_DIRECTION(...)` -> `lbm/public/instr_public.h:99-102` 当 `trdPositionDirect` 为空时，按市场、证券类型、买卖方向（含对手证券）推导持仓方向。
  - 资金账号补全分支（`fundacct` 为空）-> `lbm/public/instr_public.h:105-153`：
    - 若请求已给 `secuid`，先 `QuerySecuid(mktCode, secuid)` 查 `rtcm_secuid`，再把 `pSecuid->m_szFundacct` 回填到 `fundacct` -> `lbm/public/instr_public.h:107-116`, `lbm/public_utility/busiutility_qry_acct.h:369`。
    - 若未给 `secuid`，先 `QueryProjectacct(projectId)` 查 `rtcm_projectacct` 取项目类型，再 `CONVERT_FUNDACCTTYPE(...)` 算资金账户类型，随后按 `(project_id, fundacct_type)` 调 `QueryFundacctlink(...)` 查 `rtcm_fundacctlink` 并回填 `fundacct` -> `lbm/public/instr_public.h:129-152`, `lbm/public_utility/busiutility_qry_acct.h:413,435`。
    - 场外且现金管理特例会强制把资金账户类型改成 `FUNDACCT_TYPE_SECURITY` -> `lbm/public/instr_public.h:139-140`。
  - 股东账号补全分支（`secuid` 为空）-> `lbm/public/instr_public.h:156-165`：
    - 调 `QuerySecuidByMarketFundacct(mktCode, fundacct, trdPositionType)` 反查 `rtcm_secuid`，命中后回填 `secuid` -> `lbm/public_utility/busiutility_qry_acct.h:339`。
    - 该查询内部会在匹配集合里优先返回主股东账户（部分市场码例外），不是简单取第一条记录 -> `lbm/public_utility/busiutility_qry_acct.h:347-353`。
  - 席位补全与一致性校验 -> `lbm/public/instr_public.h:167-195`：
    - 当 `seatNo/mainseat` 缺失或 `pSecuid` 未就绪时，会再做一次 `QuerySecuid(mktCode, secuid)` 确保拿到股东账户主记录。
    - 最终把 `seatNo`、`mainseat` 默认回填为 `pSecuid->m_szCtdnSeatNo`。
    - 若请求显式给了 `mainseat` 且与股东账户席位不一致，直接报错返回。

- `CTrdDataIDX::InitCacheByQuery(...)` -> `lbm/public/trddataindex.h:61` 以固定顺序加载业务、账户、资产和市场相关缓存。
  - 顺序依赖是强约束（注释明确“不能改顺序”）-> `lbm/public/trddataindex.h:66`：
    - 先 `InitCacheBsconfig/InitCacheFund/InitCacheAvlctrlmodel`，建立业务配置和可用控制模型基线。
    - 再 `InitCacheStock` 后立即把 `pParam->m_szScrId` 回写为标准证券内码，后续冻结证券、关联证券、持仓查询都依赖这个标准化结果 -> `lbm/public/trddataindex.h:76-79`。
    - 然后才加载 `secuid/projectacct/projectasset/fundacctlink/fundacct`，因为后续 `combstkbal`、风控/费用/可用校验都要用到账户与资金维度主键。
  - 必须命中否则直接抛错（`JSTPAtomRaiseException`）：
    - `InitCacheBsconfig`、`InitCacheStock`、`InitCacheStocksub`、`InitCacheSecuid`、`InitCacheProjectacct`、`InitCacheFundacctlink`、`InitCacheFundacct`、`InitCacheComb`、`InitCacheMarket`、`InitCacheSeat` -> `lbm/public/trddataindex.h:190-452`。
  - 缺记录时会自动补建再重查：
    - `InitCacheProjectasset` 查不到 `rtfa_projectasset` 时先插入默认资产记录（`ccy=RMB`），再重新查询；二次查询仍失败才抛错 -> `lbm/public/trddataindex.h:389-405`。
    - `InitCacheCombstkbal` 查不到 `rtfa_combstkbal` 时先按当前参数生成一条持仓记录并写入，再把指针挂回缓存；若需要校验冻结证券持仓，还会额外查目标持仓，不存在则抛错 -> `lbm/public/trddataindex.h:255-316`。
  - 条件初始化（命中条件才查，不命中直接返回）：
    - `InitCacheHk_stock`、`InitCacheHkExrate` 仅港股通市场执行 -> `lbm/public/trddataindex.h:230-240,456-468`。
    - `InitCacheStkprice` 会跳过一组 `bsflag`（如 `7H/7I/05/0D/2C/6B/6S/0A`），其余场景必须查到行情快照 -> `lbm/public/trddataindex.h:471-490`。
    - 信用相关缓存 `InitCacheCreditinst/InitCachePledgestkrate/InitCacheTargetstk` 仅在 `BsflagIsCreditOpen(...)` 且资产单元是信用类型时有效 -> `lbm/public/trddataindex.h:124-134,521-560`。
    - 期权/期货/权证/LOF 相关初始化会统一调用对应 `InitCache*`，但是否真正落查询由各方法内部按 `bsflag`、市场和证券类型再判断 -> `lbm/public/trddataindex.h:136-186`。

- `DoDirectBusiness()` 的实际执行体取决于 `CreateInstance()` 返回的子类。
  - `CInstrDirBsflag0A_0K_upp::DoDirectBusiness()` -> `lbm/atom_rtfa_instruction_stk/instr_direct_business_bsflag_0A_0K_upp.h:47` 按 `0A/0B/0C/.../0K` 继续细分处理；当前常见 `0B` 会走 `chkbusiness_bsflag_0B()`。
    - `chkbusiness_bsflag_0B()` -> `lbm/atom_rtfa_instruction_stk/instr_direct_business_bsflag_0A_0K_upp.h:127` 先按买入方向调用 `GetRealpriceAndInstramt(...)` 统一价格与金额口径，再在金额单模式调用 `GetAmtInstrqty(...)` 反推合法数量；若市场是港股通，会把指令清算速度改为 `2`。
    - `GetRealpriceAndInstramt(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_cal.h:46` 先根据 `priceLimitType + 输入价格/数量/金额` 确定报单价格类型，再通过 `GetReportPriceAndQtyStandard(...)` 求真实价格；随后按金额单/数量单规则回填 `m_dbInsAmt`，并在非金额单模式下按港股汇率折算，最终把 `m_dbInsFrzAmt` 设为当前指令金额。
    - `GetAmtInstrqty(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_cal.h:113` 仅金额单路径生效；先算金额单单位价格，再按整手规则把金额反推为数量并回写 `m_dbInsQty`；修改指令且“新金额等于已执行金额”时会把数量钉到旧指令已成交数量，避免重复放大。
  - `CInstrDirBsflag0L_0Z_upp::DoDirectBusiness()` -> `lbm/atom_rtfa_instruction_stk/instr_direct_business_bsflag_0L_0Z_upp.h:45` 按 `0Q/0R/0S/.../0Z` 继续细分处理；当前常见 `0S` 会走 `chkbusiness_bsflag_0S()`。
    - `chkbusiness_bsflag_0S()` -> `lbm/atom_rtfa_instruction_stk/instr_direct_business_bsflag_0L_0Z_upp.h:166` 与 `0B` 一样先做价格/金额统一和金额单数量反推，再调用 `GetBlockSale()` 生成减持统计对象；港股通同样强制清算速度为 `2`。
    - `GetBlockSale()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_cal.h:172` 用当前证券、席位、系统日、server id 组装 `CRtfa_blocksalestat`；修改指令会先减去旧指令数量后再入 `m_vBlockSale`，后续由 `WriteCacheBlockSaleStat()` 统一落表。

- `DoDirectBusinessHold()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:243` 在股票路径里继续下钻到持仓工具类。
  - `CInstrUtillHold::chkbusiness_stkhold_available(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:56` 入口先做“旧单回补准备 + 多级短路”：
    - `calc_old_instrstkqty()` 按 `instructstock key` 读取旧指令证券的 `oldInsQty/oldApplyQty`，写入 `m_stInstrOccur` 供后续所有校验共用 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:361-384`。
    - 外部接口、全局关闭可用校验、当前证券不需要校验数量、前台关闭持仓可用校验、业务标志显式禁用持仓校验时直接返回 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:61-89`。
  - 路由层会按 `bsflag` 和市场切到不同子校验器，而不是只走通用校验：
    - ETF 申赎（`01/02`）、融资融券（`RB/RS/5S/6S`）、要约/权证/开放式基金/质押/期货/银行间等各有专用函数；
    - 大部分普通卖出或减持相关路径最终会回落到 `chkbusiness_stkhold_available_common()`；
    - `0S/1J/1L/1N/1Q/1Z` 且满足深/沪减持控制条件时，会先做一次减持额度校验再继续后续持仓校验 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:92-242`。
  - `chkbusiness_stkhold_available_0S_1J_1L_1N_1Q_1Z()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:1206` 的减持额度口径：
    - 先组装 `CBlocksale` 并调用 `AtomComm_BlockSaleCal(...)` 得到竞价额度/大宗额度/限额；
    - 比较量统一用 `本次新增量 = insQty - totalOrdQty`，并把 `dbOldInstrqty`（旧指令释放量）加回可用侧；
    - 按 `reductionctrlflag`、`bsflag`、`specialBusiFlag` 选择 `AuctionQuota/BlockQuota/Blocklimitamt` 作为比较口径，不足即抛异常（`880236619/620/621`）。
  - `chkbusiness_stkhold_available_common()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_hold.h:791` 的通用可用口径：
    - 先按 `bsflag` 归一查询方向（如 `7O/7P -> 7B`），再按 `NeedCheckFrzStk(...)` 决定查普通持仓还是目标/冻结持仓，统一通过 `AtomComm_HoldAvail(...)` 取可用量；
    - 可用量调整顺序是：`holdAvail + oldInstrRelease - currentLoopAlreadyOccupied`；
    - 之后比较 `adjustedAvail` 与 `insQty - totalOrdQty`，不足时回写 `dbAvlstkqty/dbTotalOccupystkqty` 并抛 `FIXERRCODE_INSTRCHECKAVL`；
    - 最后再做一次“累计已委托量不能超过指令量”校验，超限抛 `880116307`。

- `DoDirectPridictfee()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:415` 股票路径最终落到 `CInstrUtilFee::calbusiness_pridictfee()`。
  - `calbusiness_pridictfee()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:47` 先走一组“早退过滤矩阵”：
    - 外部接口（`Gloobal_IsExtInterface`）直接返回，不算预测费。
    - 混合配置 `MIXCFG_8330906 != '1'`、现金控制方式为“不控”、资金方向非减少、市场不在白名单、投资业务类型不在 `1DE` 都直接返回 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:53-62`。
    - `bsflag` 命中 `01/02/03/04/05` 时直接返回；港股通卖出类（`0S/0a`）也直接返回 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:64-73`。
  - 金额口径推导（`dbInstramt`）：
    - 数量控制型（`m_cInsScrCtrlType == '2'`）先定价格：市价/不限价用前台价格；限价路径按债券类业务判断是否要把应计利息（`HdynBondIntr/NextIntr`）加到净价上，再 `Round(insQty * price, 2)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:77-121`。
    - 金额控制型则直接取 `m_dbInsAmt` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:122-125`。
  - 港股通换汇：若 `MARKET_HK_STK`，买入用卖出参考汇率、卖出用买入参考汇率；汇率必须大于 0，否则抛异常；金额按汇率折成人民币后再计费 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:127-141`。
  - 主费用计算：`m_pCal->m_objFee.CalculateTradeFee(insQty, dbInstramt, realPrice)` 生成当前证券预测费 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:143-145`。
  - `0G + 可交换债` 特例补费：当 `bsflag=0G` 且当前证券类型是 `STKT_KJHZQ`，会再查询转股目标证券与子表，按转股数量/金额额外算一笔费用并累加到总费用；最后统一回写 `m_pStockParam->m_dbPredictFee` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fee.h:146-181`。

- `DoDirectfundasset()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:384` 股票路径最终落到 `CInstrUtilFund::cal_fundasset_available()`。
  - `cal_fundasset_available()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:67` 先做“是否需要资金占用”的总开关（`capitaldirect == STOCK_FUND_D_NO` 直接返回），再按 `market + projectType + bsflag` 分派占用算法。
    - 股票市场：普通资产单元会在 `normal/bond/协议回购/买断回购/国债预发行/债券借贷/...` 分支里择一执行；信用资产单元走信用专用分支；期权类 `7A/7B/7C/7F/7J/7G/7N` 走期权资金占用分支 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:72-123`。
    - 期货市场：期权类仍走期权占用，否则走 `cal_fundasset_available_future()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:124-139`。
    - 港股通/场外/第三板块/北交所/票据市场按各自条件回落到 normal 或 bond 类占用函数 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:140-170`。
  - `cal_fundasset_available_stk_normal()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:209` 是当前 0B/0S 最常见口径：
    - 先取预测费符号口径 `dbFee = get_instr_pridictfee()`（金额单模式预测费按 0 处理）。
    - `0H` 仅占用费用；`02` 用 `insFrzAmt`；其余普通路径用 `insAmt + dbFee`。
    - 同时把 `m_dbTotalOccupyamt` 统一记录为 `insAmt` 口径，供后续资金可用比较与输出使用。
  - `cal_fundasset_available_stk_bond()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:230` 在债券分支里会区分净价/全价与数量单/金额单：
    - 净价交易会把应计利息加进占用金额；
    - 数量单和金额单分别按 `qty*price(+intr)` 或 `insAmt` 口径计算；
    - 最终把本次占用写回 `m_dbInsFrzAmt`，后续直接用于 `SetInstrStockAmt` 和写表。
  - 指令维度补偿顺序（分派计算后统一执行）：
    - 修改指令走 `cal_fundasset_available_oldinstr()`：按旧指令证券 key 回补旧冻结，金额单扣已成交金额/费用，数量单按“剩余可用比例”重算，并写回 `m_dbOldFrzAmt` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:890-955`。
    - 新下达走 `cal_fundasset_available_nextdayinstr()`：扣除当日累计委托量对应占用，避免重复冻结 -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:966-995`。

- `DealDirectData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:334` 继续下钻到 `CInstrData` 和 `CProcessInsManager`。
  - `CInstrData::SetInstrStockAmt(...)` -> `lbm/atom_public/instrdata.h:976` 把当前证券的 `m_dbInsFrzAmt` 和 `m_dbBeginInsFrzAmt` 统一设成本轮算出的 `m_dbAssetOccur`；修改指令场景还会通过 `CInstructionDeal::GetInstrStockstatusEnter(...)` 重新计算指令证券状态字段。
  - `CProcessInsManager::ProcessInstrDealEx(...)` -> `lbm/atom_public/process_ins_manager.h:66` 会先把 `pTrdIDX` 里的缓存指针（`stock/targetCombstkbal/stockoptions/warranttrd...`）和输出容器绑定到管理器，再构造“本次应记账差量”。
    - 修改指令差量口径：若 `m_nInstrflag == BUS_FLAG_INS_MODI`，先按 `instructstock key` 在旧指令索引 `m_mOldInstructStkIDX` 找旧证券，调用 `GetInstAmt(...)` 算旧口径 `stOrderCalInfo`；随后对当前新证券再算一版 `m_stOrderCalInfo`，最后做逐字段相减（`Insqty/Instrmargin/InsamtWithNet/InsamtWithBondintr/InsamtWithNetHK/InsTotalFee/MdInsQty/JdInsQty`），保证后续资产持仓只记录“本次修改净增量” -> `lbm/atom_public/process_ins_manager.h:97-124`。
    - `atom_process_initacct()` -> `lbm/atom_public/process_ins_manager.h:983` 先用 `AssignKey` 生成本次 `rtfa_combstkbal` 主键，再把证券 id 切到冻结证券 `frzId`；融资融券变更/开放式基金变更会额外初始化目标持仓键。
    - `atom_process_asset()` -> `lbm/atom_public/process_ins_manager.h:135` 用 `ConvertProcessType(...)` 做处理器分派（普通股票/期权/信用/ETF/协议回购/银行间/票据/场外等）；当前 83300100 主链常见路径是 `PROCESSTYPE_STK_NORMAL -> processinstr_normal()`。
    - `processinstr_normal()` -> `lbm/atom_public/process_ins_manager.h:219` 先做业务短路判断（如部分新股场景直接返回），再 `ConvertStkid` 标准化持仓主键并计算 `fundctrl_speed`；随后三段式调用 `ProcessFundStk -> ProcessStock -> ProcessAssetStk`，分别产出资金、持仓、资产增量对象。权证行权场景会再计算目标证券数量并追加一组目标持仓/目标资产增量。
    - 输出容器回传：本轮生成的 `m_objInstrcombstkbalU` 与 `m_objInstrprojectassetU` 会 push 到 `m_pInstrCapital->m_vInstrCombstkbalU`、`m_vInstrProjectassetU`，供 `CInstrData::WriteTable` 统一落表 -> `lbm/atom_public/process_ins_manager.h:132-134`。

- `DealInquiryData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:363` 股票路径继续下钻到询价回写处理器。
  - `CProcessInquiryCancel::ProcessInquiryCancelDeal(...)` -> `lbm/atom_public/process_inquiry_cancel.h:58` 先绑定 `nOperType/preInsSno/preInsModSno` 与两个输出容器指针，再按“先状态变更、后反向记账”的顺序执行。
  - `atom_process_querypreinschg()` -> `lbm/atom_public/process_inquiry_cancel.h:75` 先查两类前置流水：
    - `QueryPreinsAssetChg(...)` / `QueryPreinsSkbalChg(...)` 分别按 `(preInsSno, preInsModSno)` 读取 `rtfa_asset_log_preins`、`rtfa_stkbal_log_preins` -> `lbm/public_utility/busiutility_qry_asset.h:506,517`。
    - 仅处理状态为 `'0'` 的记录：`INQUIRY_CANCEL` 映射为状态 `'1'`，`INQUIRY_ACCEPT` 映射为状态 `'2'`；未知操作类型直接抛异常（`83301151/83301152`）-> `lbm/atom_public/process_inquiry_cancel.h:81-113`。
    - 状态更新对象分别写入 `m_vAssetChgPreinsU`、`m_vStkbalChgPreinsU`，后续由 `WriteCacheDataPreinsAssetChg/WriteCacheDataPreinsStkbalChg` 落表。
  - `atom_process_preinsassetbook()` -> `lbm/atom_public/process_inquiry_cancel.h:121` 对同样状态为 `'0'` 的原始前置流水做一次负向运算（`obj -= preins_log`）：
    - 资产侧生成 `CInquiryProjectasset`，推入 `m_vPreinsProjectassetU`；
    - 持仓侧生成 `CInquiryCombstkbal`，推入 `m_vPreinsCombstkbalU`。
    - 这两组容器后续分别对应 `WriteCacheDataPreinsProjectasset`、`WriteCacheDataPreinsCombstkbal` 的 preins 资产簿增量写入。

- `DoDirectBusinessFund()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_business_base.h:274` 股票路径继续下钻到资金可用校验。
  - `CInstrUtilFund::chkbusiness_fundasset_available(...)` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:493` 先把当前总占用对象挂到 `m_pTotalOccur`，再按“`bsflag` + 资产单元类型 + 是否期货”分派：
    - 若 `bsflag` 属于 `7A/7B/7C/7F/7G/7N`，走 `chkbusiness_fundasset_available_stkoptions()`（期权路径）-> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:497-505`。
    - 否则若资产单元是普通型 `PROJECTACCT_TYPE_NORMAL`，再按 `Bsflag_IsFuture(...)` 分到 `chkbusiness_fundasset_available_ft()`（期货）或 `chkbusiness_fundasset_available_normal()`（普通股票）-> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:506-515`。
    - 否则若资产单元是信用型 `PROJECTACCT_TYPE_CREDIT`，走 `chkbusiness_fundasset_available_credit()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:517-519`。
  - `chkbusiness_fundasset_available_normal()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:631` 是当前 0B/0S 主链最常见路径：
    - 先把市场写入 `m_objAvailParam`，再用 `GetEtfRtgsFundctrl(...)` 计算资金控制速度并调用 `AtomComm_FundAvail(...)` 查询 `rtfa_projectasset` 口径可用。
    - 最终比较口径是 `dbFundEffect = m_dbAssetOccur - m_dbOldFrzAmt`（本次净新增占用）；若 `dbFundAvail < dbFundEffect`，就把回补项（T0/T1/T2 预买等）累加到 `m_dbInsfundavl`，并按 `FIXERRCODE_INSTRCHECKAVL` 抛出资金不足。
  - `chkbusiness_fundasset_available_ft()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:567`（期货）会把预测费用并入 `m_dbExPreFtMargin`，按 `PROJECTASSET_AVAIL_TYPE_FD_FT` 查可用，并在比较时额外考虑“同方向可抵扣可用”（`m_dbFt_dbavail`）；不足同样抛 `FIXERRCODE_INSTRCHECKAVL`。
  - `chkbusiness_fundasset_available_stkoptions()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:527`（期权）会按买卖方向累计 `m_dbExPreRightAmt/m_dbExPreFtMargin`，当可用为负时记录 `m_dbInsfundavl` 并抛资金不足异常。
  - `chkbusiness_fundasset_available_credit()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_util_fund.h:666`（信用）当前主干代码里大量细化校验为注释态，现状更接近“预留入口/兼容分支”，文档按代码现状记录，不推断未启用逻辑。

- `WriteBusinessData()` -> `lbm/atom_rtfa_instruction_comm/instr_direct_flow.h:297` 调用 `m_objInstrData.WriteTable(&m_objTrdIDX)` 写回指令相关表，然后再做一次港股风险金检查。
  - `CInstrData::WriteTable(...)` -> `lbm/atom_public/instrdata.h:264` 按固定顺序执行“主记录 -> 资产持仓增量 -> preins 增量 -> 旧单状态回写 -> 各业务附表 -> 统计与日志”的批量写表。
  - `WriteCacheDataInstruction()` -> `lbm/atom_public/instrdata.h:356`, `lbm/tables/rtfa_instruction.h:213` 调用 `writetable_instruction_insert/update(...)` 写 `rtfa_instruction` 主记录。
  - `WriteCacheDataInstructStock()` -> `lbm/atom_public/instrdata.h:381`, `lbm/tables/rtfa_instructstock.h:359` 遍历 `m_vInstructstockParam` 调用 `writetable_instructstock_insert/update(...)` 写 `rtfa_instructstock` 明细。
  - `WriteCacheDataProjectasset()` / `WriteCacheDataCombstkbal()` -> `lbm/atom_public/instrdata.h:668,677` 遍历 `m_stInstrCapital.m_vInstrProjectassetU/m_vInstrCombstkbalU`，把 `ProcessInstrDealEx` 输出的增量逐条落到 `rtfa_projectasset`、`rtfa_combstkbal`；其中 `combstkbal` 写前会把 `m_nProductId` 置 `0`，保持该表增量口径一致。
  - `WriteCacheDataPreinsAssetChg()` / `WriteCacheDataPreinsStkbalChg()` -> `lbm/atom_public/instrdata.h:688,697` 把询价状态变更增量写入 `rtfa_asset_log_preins`、`rtfa_stkbal_log_preins`。
  - `WriteCacheDataPreinsProjectasset()` / `WriteCacheDataPreinsCombstkbal()` -> `lbm/atom_public/instrdata.h:706,715` 遍历 `m_stAssetBookPreinsCapital.m_vPreinsProjectassetU/m_vPreinsCombstkbalU`，把询价反向资产簿增量写入 `rtfa_projectasset_preins`、`rtfa_combstkbal_preins`。
  - `WriteCacheDataOldInstr()` -> `lbm/atom_public/instrdata.h:634` 仅 `BUS_FLAG_INS_MODI` 生效：把旧 `rtfa_instruction/rtfa_instructstock` 状态回写为“修改态”，避免旧版本仍被当作有效原始状态。
  - `WriteCacheDataInquirelog()` -> `lbm/atom_public/instrdata.h:481` 仅在“有询价日志且当前是新下达（`BUS_FLAG_INS_DIRI`）”时执行；存在同 key 旧记录时走 `update + repeatAppTimes++`，否则 `insert`。
  - `WriteCacheDataBankinstrbbimpawn/.../WriteCacheDataOutstockoptionFee_instr()` -> `lbm/atom_public/instrdata.h:280-296,415-631` 一组附属业务写表，统一采用“对应向量非空才写”的条件模式。
  - `WriteCacheBlockSaleStat()` -> `lbm/atom_public/instrdata.h:368` 把 `m_vBlockSale` 中的减持统计写入 `rtfa_blocksalestat`。
  - `Writetable_rtfa_tradeqtyamt()` / `Writetable_rtfa_lockstkbal()` -> `lbm/atom_public/instrdata.h:1446,1451` 分别落 `rtfa_tradeqtyamt` 和 `rtfa_lockstkbal`。

## TODO

- `BUSINESS_BANK` / `BUSINESS_BILL` / `BUSINESS_OUT` 三条原子分支当前未展开。
- `0A-0K` 和 `0L-0Z` 区间内除 `0B`、`0S` 之外的其他 `bsflag` 分支当前未逐个展开。
